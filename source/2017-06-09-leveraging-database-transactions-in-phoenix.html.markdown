---
title: "Leveraging Database Transactions For Complex Forms in Phoenix"
date: 2017-06-09
author: Derrick Reimer
tags: elixir
---

I recently set out to implement user registration for a project I'm working on
in Elixir/Phoenix. It wasn't long before I encountered a challenge that I have
stumbled upon with every other ORM library: accepting a collection of form
inputs and saving it across multiple (related) records in the database.

There's more than one way to tackle the problem (with varying degrees of
elegance), but I discovered that [Ecto](https://github.com/elixir-ecto/ecto)
lends itself particularly well to solving this problem once you are familiar
with tools available.

READMORE

## The registration form

Let's assume that you have a `users` table and a `teams` table, and upon
submitting the registration form you need to create a new team record and a
new user record (the team owner).

At a minimum, our form needs to collect the following fields:

- Team name
- Email address
- Password

Since this HTML form includes fields that belong in multiple database records,
it does not make sense to bind the form directly to the `User` or `Team` changesets.

One alternative is to [bind the form to `@conn` structure](https://hexdocs.pm/phoenix_html/Phoenix.HTML.Form.html#module-with-connection-data):

```
<%= form_for @conn, team_path(@conn, :create), [as: :signup], fn f -> %>
  <div class="form-field">
    <%= label f, :team_name, "Team Name" %>
    <%= text_input f, :team_name %>
  </div>

  <div class="form-field">
    <%= label f, :email, "Email" %>
    <%= email_input f, :email %>
  </div>

  <div class="form-field">
    <%= label f, :password, "Password" %>
    <%= password_input f, :password %>
  </div>

  <div class="form-controls">
    <%= submit "Sign up" %>
  </div>
<% end %>
```

Upon submission, the form data is available in the request params under the
`"signup"` key. This may be suitable for very simple use cases, but quickly becomes
cumbersome when you need more complicated logic, like data validations and
default values.

Fortunately, Ecto changesets do not have to correspond to an actual database table!
This means we can still use a changeset to implement our validation logic
in a "virtual" model. Let's call it `Registration` and drop it in our models directory:

```elixir
# web/models/registration.ex
defmodule MyApp.Registration do
  import Ecto.Changeset

  @types %{
    team_name: :string,
    email: :string,
    password: :string
  }

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def form_changeset(struct, params \\ %{}) do
    {struct, @types}
    |> cast(params, Map.keys(@types))
    |> validate_required([:team_name, :email, :password])
    |> validate_length(:team_name, min: 1, max: 255)
    |> validate_length(:email, min: 1, max: 254)
    |> validate_length(:password, min: 6)
  end
end
```

In the controller, we can summon a new changeset to bind to the form:

```elixir
# web/controllers/team_controller.ex
defmodule MyApp.TeamController do
  use MyApp.Web, :controller
  alias MyApp.Registration

  def new(conn, _params) do
    changeset = Registration.form_changeset(%{})
    render conn, "new.html", changeset: changeset
  end

  def create(conn, %{"signup" => signup_params}) do
    changeset = Registration.form_changeset(%{}, signup_params)

    if changeset.valid? do
      # TODO: persist the data
    else
      changeset = %{changeset | action: :insert}
      render conn, "new.html", changeset: changeset
    end
  end
end
```

In the `create` action, we check to see if the validations pass; if not,
then we re-render the form (with errors). The `%{changeset | action: :insert}`
step is important, because it signifies to the form helper that errors should
be rendered.

The template looks essentially the same as the first example, except the
first argument is `@changeset` instead of `@conn`:

```
<%= form_for @changeset, team_path(@conn, :create), [as: :signup], fn f -> %>
  <div class="form-field">
    <%= label f, :team_name, "Team Name" %>
    <%= text_input f, :team_name %>
    <%= error_tag f, :team_name %>
  </div>

  <!-- snip -->
<% end %>
```

## Persisting the data

The persistence phase should go something like this:

- Insert a record in `teams`
- Insert a record in `users` (with a foreign key pointing to the team)
- In the event either operation fails, rollback all inserts

This is a perfect candidate for a database transaction because we
want to guarantee rollback on failure. Conveniently, Ecto comes with a handy module called [`Ecto.Multi`](https://hexdocs.pm/ecto/Ecto.Multi.html)
that facilitates grouping a pipeline of database operations for transactions.

Let's build on our `Registration` module by adding a `operation` function, and
add `registration_changeset` functions to the `User` and `Team` models. (One of the steps not
implemented in this example is the `put_password_hash` function in the `User`
module which is responsible for transforming the raw password into a hashed one
for storage).

```elixir
# web/models/team.ex
defmodule MyApp.Team do
  use MyApp.Web, :model

  def registration_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name])
  end
end

# web/models/user.ex
defmodule MyApp.User do
  use MyApp.Web, :model

  def registration_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:team_id, :email, :password])
    |> put_password_hash
  end
end

# web/models/registration.ex
defmodule MyApp.Registration do
  import Ecto.Changeset
  alias Ecto.Multi

  alias MyApp.Team
  alias MyApp.User

  # ...

  def operation(changeset) do
    Multi.new
    |> Multi.insert(:team, team_changeset(changeset))
    |> Multi.run(:user, fn %{team: team} ->
      changeset
      |> user_changeset()
      |> put_change(:team_id, team.id)
      |> Repo.insert
    end)
  end

  defp team_changeset(changeset) do
    params = %{name: changeset.changes.team_name}
    Team.registration_changeset(%Team{}, params)
  end

  defp user_changeset(changeset) do
    params =
      changeset.changes
      |> Map.take([:username, :email, :password, :time_zone])

    User.registration_changeset(%User{}, params)
  end
end
```

The `Registration.operation` function is responsible for building an `Ecto.Multi`
structure that can be passed to the [`Repo.transaction`](https://hexdocs.pm/ecto/Ecto.Repo.html#c:transaction/2)
function. The first step inserts the `Team` record, and the second step
receives the newly-created `Team` and associates the `User` to it when inserting.

Now that we have an function for generating our operation, we can utilize it
in our controller.

```elixir
defmodule MyApp.TeamController do
  use MyApp.Web, :controller

  # ...

  def create(conn, %{"signup" => signup_params}) do
    changeset = Registration.form_changeset(%{}, signup_params)

    if changeset.valid? do
      case Repo.transaction(Registration.operation(changeset)) do
        {:ok, %{team: team, user: user}} ->
          conn
          |> put_flash(:info, "Thanks for registering!")
          |> redirect(to: home_path(conn, :index))
        {:error, _, _, _} ->
          conn
          |> put_flash(:error, "Uh oh, something went wrong. Please try again.")
          |> render("new.html", changeset: changeset)
      end
    else
      changeset = %{changeset | action: :insert}
      render conn, "new.html", changeset: changeset
    end
  end
end
```

The result is a nice and clean separation of concerns between form data and
persistence operations, all while making good use of data integrity features
built into PostgreSQL.
