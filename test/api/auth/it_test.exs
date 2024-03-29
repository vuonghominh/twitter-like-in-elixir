defmodule Api.Auth.ItTest do
  use App.ConnCase
  alias Api.User.Service

  @current_user_attrs %{
    email: "current@email",
    password: "password"
  }

  def fixture(:user) do
    {:ok, user} = Service.create_user(@current_user_attrs)
    user
  end

  describe "Logout" do
    setup [:create_user]

    test "responses unauthorized" do
      conn = post("/api/auth/logout")
      assert conn.state == :sent
      assert conn.status == 401
      assert response_json(conn.resp_body) == %{"message" => "unauthorized"}
    end

    test "response ok and no more auth tokens in db", %{user: user} do
      conn = post("/api/auth/logout", nil, Service.generate_auth_token(user))
      assert conn.state == :sent
      assert conn.status == 200
      assert response_json(conn.resp_body) == %{"message" => "ok"}

      user = Service.get_user_by_id(user.id)
      assert length(user.auth_tokens) == 0
    end
  end

  describe "Login" do
    setup [:create_user]

    test "responses error" do
      conn = post("/api/auth/login")
      assert conn.state == :sent
      assert conn.status == 400
      assert response_json(conn.resp_body) == %{
        "message" => "error",
        "data" => %{
          "email" => "is required"
        }
      }
    end

    test "responses unauthorized error" do
      conn = post("/api/auth/login", %{email: "any@email", password: "1234"})
      assert conn.state == :sent
      assert conn.status == 401
      assert response_json(conn.resp_body) == %{"message" => "email_and_password_do_not_match"}
    end

    test "responses OTP code when user credentials are good" do
      conn = post("/api/auth/login", %{
        email: @current_user_attrs.email,
        password: @current_user_attrs.password
      })
      %{"data" => %{ "code" => code }} = response_json(conn.resp_body)
      assert conn.state == :sent
      assert conn.status == 200
      assert is_binary(code)
    end

    test "responses unauthorized error when OTP code is not good" do
      credentials = %{
        email: @current_user_attrs.email,
        password: @current_user_attrs.password
      }
      post("/api/auth/login", credentials)
      conn = post("/api/auth/login", Map.put(credentials, :code, "1234"))
      assert conn.status == 401
      assert response_json(conn.resp_body) == %{"message" => "unauthorized"}
    end

    test "response user when user credentials and OTP code are good" do
      credentials = %{
        email: @current_user_attrs.email,
        password: @current_user_attrs.password
      }
      conn = post("/api/auth/login", credentials)
      %{"data" => %{ "code" => code }} = response_json(conn.resp_body)
      conn = post("/api/auth/login", Map.put(credentials, :code, code))
      assert conn.status == 200
      %{"data" => %{ "token" => token }} = response_json(conn.resp_body)
      assert token != nil
    end
  end

  defp create_user(_) do
    user = fixture(:user)
    {:ok, user: user}
  end
end