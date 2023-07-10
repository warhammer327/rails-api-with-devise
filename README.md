# Ruby on Rails: Authentication, Access Control & Rate Limiting

## Steps necessary to get the application running on local machine:

* Ruby version: 3.0

* Rails version: 7.0

* Database: Postgres

* Database creation: ``` rails db:create; rails db:migrate ``` inside the project root.

* To run the project: ``` rails s ```

In this tutorial, we will be diving down into ruby on rails API. You will learn how to
authenticate user with devise gem as well as authorization using cancancan gem.
Afterward we will take a look how to implement access control.

## Getting started

At first, lets create a project. I'll be using Ruby 3.0.0 and Rails 7 for this purpose
along with Postgres database and Postman. Make sure to setup Postgres and Postman
before proceeding. To create project:

```
> rails new [projectname] --api -d postgresql
> cd [projectname]
> rails db:create
```
In commands above, we have created an lean Rails project that focuses on API leaving
out parts that are required only by a full-stack application. Then entering the
project directory, we will create a database. Now, there are some things we have to do
before we go any further.

As this is an API only application we will have to enable the rack-cors gem by
removing comment symbol from Gemfile. Simply put, this gem allows a Rack compatible
front end app to request information from Rails back end.

Add devise and devise-jwt gem to Gemfile and run bundle install.

```
gem 'devise'
gem 'devise-jwt'
```
Now let's edit the cors.rb in _config/initializers/cors.rb_. Here, change the origins
"example.com" to origins "*". Doing so enables the application to accept request
from anywhere. Before, it could only accept requests from _example.com_. Also, remove
all the comment symbol from the snippet. It should look like this by the time you are
done.

```
Rails.application.config.middleware.insert_before 0, Rack::Cors do
allow do
origins "*"
```
```
resource "*",
headers: :any,
methods: [:get, :post, :put, :patch, :delete, :options, :head],
expose: ["Authorization"]
end
end
```
The expose directive specifies the additional response headers that are exposed to
the client. In this case, the "Authorization" header is exposed, which allows the
client to access the value of the "Authorization" header in the response.


## Authentication

### Setting up devise

Start by entering rails g devise:install into the command line. It is a Rails
generator command used to install and set up the Devise gem in a Ruby on Rails
application. It creates an initializer file _config/initializers/devise.rb_ where you
can configure various Devise options and settings. After the command is ran, you will
see some directives. As the first directive says, place
config.action_mailer.default_url_options = { host: 'localhost', port: 3000 } into
_config/environments/development.rb_.

Now go to devise.rb and find ,

```
config.navigational_formats = ['*/*', :html]
```
Remove everything from the array as we won't have to deal with navigational formats as
our application in API only application.

```
config.navigational_formats = []
```
### Creating user controller

Afterward, we will be have to generate user model. Devise will take care of that as
the command rails g devise user is run. Then, to generate controller for user run
rails g devise:controller users -c sessions registrations. The registration controller
will handle signing up users. The session controller will handle sign in and sign out.
In case these to controllers weren't not specifically mentioned the command would also
generate other controllers that are needed in full-stack application.

### Setting up devise-jwt

`devise-jwt` is a Devise extension that utilizes JWT tokens to authenticate users. It
adheres to the secure by default philosophy. Before we dive further, we have to setup
`devise-jwt` first.
You have to configure the secret key that will be used to sign generated tokens. You can do it in the Devise initializer located in `../config/initializer/devise.rb`.
```
Devise.setup do |config|
  # ...
  config.jwt do |jwt|
    jwt.secret  =  Rails.application.credentials.fetch(:secret_key_base)
  end
end
```
You will get an error when you try to run the server if you don't have the secret key setup. To generate the secret key run `rails secret`, and that would be all.
`devise-jwt` comes with three revocation strategies out of the box. The model class
serves as the revocation technique in this case. A new string column entitled `jti`
must be added to the user. JWT ID is a standard claim that is used to uniquely
identify a token.

It functions as follows:

- When a token is issued for a user, the jti claim is extracted from the model's jti
column (which is populated when the record is created).

- The incoming token jti claim is compared against the jti field for that user at
every authorized activity. Only if they are the same does the authentication pass.

- When a user asks to sign out, the jti column changes, and the given token is no
longer valid.

- To utilize it, you must add the jti column to the user model. So, run `ralis g
migratios add_jti_to_user`. This will create a empty migration file. Add the following
code in to the newly created migration file under `../db/migrate/`.


```
def change
add_column :users, :jti, :string, null: false
add_index :users, :jti, unique: true
end
```

Then run rails `db:migrate`. This will update the schema to work with `jti`. Now, open
`../app/models/user.rb` then add `include Devise::JWT::RevocationStrategies::JTIMatcher` at
the top of the user model. You will also have to add `:jwt_authenticatable` and
`jwt_revocation_strategy: self` to the model. Also, add jwt_payload as jti matcher
utilizes that function. In the end the model will look like this,
```
class User < ApplicationRecord
	include Devise::JWT::RevocationStrategies::JTIMatcher

	devise :database_authenticatable, :registerable,
	:recoverable, :rememberable, :validatable,
	:jwt_authenticatable, jwt_revocation_strategy: self

	def jwt_payload
		super
	end
end

```
### Updating Route
In routes, now we will be declaring to route that user resource will be using session
and registration controllers. If we don't mention the registration and session
controller specifically, it will utilize the registration and session controller of
the devise gem.
```
Rails.application.routes.draw do

	devise_for :users, controllers: {
		sessions: 'users/sessions',
		registrations: 'users/registrations'
	}

end
```
Lets head over to `../config/initializers/devise.rb` again and add JWT dispatch request, revocation request and expiration time.
```
config.jwt  do |jwt|

	jwt.secret  =  Rails.application.credentials.fetch(:secret_key_base)

	jwt.dispatch_requests  = [
		['POST',%r{^/users/sign_in$}]
	]
	jwt.revocation_requests  = [
		['DELETE',%r{^/users/sign_out}]
	]

	jwt.expiration_time  =  760.minutes.to_i

end
```
### Little patch
Add the following code inside `/config/application.rb` to enable session store into the API application, otherwise the application will throw an error when using POST header.
```
config.api_only  =  true
config.session_store  :cookie_store, key:  '_interslice_session'
config.middleware.use  ActionDispatch::Cookies
config.middleware.use  config.session_store, config.session_options
config.middleware.use  Rack::Attack
```

## Authentication in action
Now it is time for a field test. Let's run the server and then open Postman. Hit the the `localhost:3000/users/` with POST method and with a user object in body.
```
{
"user":  {
	"email":  "super@test.com",
	"password":  "123456"
	}
}
```
If you have done everything correctly, then you should see that user has been created successfully in the server log with a success code 200. Check the response header and copy the bearer token from authentication.
Create another tab with DELETE method in postman. Now hit `localhost:3000/users/sign_out`, before hitting send, go to header, then add `Authorization` field and pass the value as `Bearer  [token]`. Once you hit send you are likely to get an error `...undefined method 'respond_to'....`. To solve it we will have to add `respond_to` method to both registration and session controller. Add the following into registration controller.
```
class  Users::RegistrationsController < Devise::RegistrationsController
	respond_to  :json

	private
		def  respond_with(resource, option={})
			if  resource.persisted?
				render  json: {
					status: { code:  200, message:  'signed up successfully', data:  resource}
				}, status:  :ok
			else
				render  json: {
				status: {message:  'operation failed', errors: resource.errors.full_messages},
				status:  :unprocessable_entity
			}
		end
	end
end
```
In session controller we will have to override `respond_to_on_destroy` method to show our response otherwise it will use method provided by devise. So, add the private methods shown below.
```
class  Users::SessionsController < Devise::SessionsController
	respond_to  :json

	private
		def  respond_with(resource, option={})
			render  json: {
			res:  resource,
			status: { code:  200, message:  'signed in: '+current_user.email , data:  current_user}
			}, status:  :ok
		end

		def  respond_to_on_destroy
		jwt_payload  =  JWT.decode(request.headers['Authorization'].split(' ')[1],Rails.application.credentials.fetch(:secret_key_base)).first
		current_user  =  User.find(jwt_payload['sub'])
		if  current_user
			render  json: {
			status:  200,
			message:  "signed out user: "  +  current_user.email
			}, status:  :ok
		else
			render  json: {
			status:  401,
			messages:  "user has no active session"
			}, status:  :unauthorized
		end
	end
end
```
What this function basically does is that it takes out the token, then find if the current user exists. Afterward, we prepared response accordingly.
Now if you try hitting `localhost:3000/users/sign_out` with proper credentials and the token you should see the response we set earlier for successful signing out.
Let's check how we can sign in. For that make a POST method as `localhost:3000/users/sign_in`. Populate the body as shown with proper credentials. For example,
```
{
"user":  {
	"email":  "super@test.com",
	"password":  "123456"
	}
}
```
If you check the server log you will see somehting like `Processing by Users::SessionController#create....` which confirms that sign in operation worked successfully.
We will now add a mechanism to see currently logged in member. In `app/controller/` make a file `member_details.rb` as follows.
```
class  MembersController < ApplicationController

before_action  :authenticate_user!
	def  index
		render  json:  current_user, status:  :ok
	end
end
```
And add `get  '/member_details'  =>  'members#index'` to `routes.rb` in config. Create a GET method in Postman with `localhost:3000/member_details`. Once you hit send, you will see which member is logged in.

## Making CRUD operations
This is the part where things gets interesting as in this portion we will be making the API end points. Lets create model,
```
rails g model company name year user:references
```
As we are using reference, we will have to let the user model know about this too. So, add `has_many :companies` to `user.rb` model. Now run the command `rails db:migrate`. As companies must have user assigned to it, add validation by incorporating the in the `company.rb` model.
```
validates  :name, presence:  true, uniqueness:  true
validates  :year, presence:  true
```
Afterward we will have to update the router letting it know about our newly created resource.
```
namespace  :api  do
	namespace  :v1  do
		resources  :companies
	end
end
```
Create `companies_controller.rb` in `../app/controller/api/v1/`.  Populate the controller as shown in the repository. After then, create api_controller inside `../app/controller` and add this so it will authenticate user in every hit.
```
class  ApiController < ApplicationController
	before_action  :authenticate_user!
end
```
## Access control
We will start by adding `rails g migration add_role_to_users role:string`. This will create a migration file adding role to user table. Then run `rails db:migrate`.  Now, add the following to user model.
```
ROLES  =  %w{super_admin admin manager editor collaborator}
ROLES.each  do |role_name|
	define_method  "#{role_name}?"  do
		role  ==  role_name
	end
end
```
To define role abilities, we will install `cancancan` gem. Add the gem to gemfile and do `bundle install`.
Next, you'll generate the Ability class which will define the roles and abilities. Open your terminal and run the following command. This command will generate a file named `ability.rb` in the `app` directory.
```
rails generate cancan:ability
```
Open the `ability.rb` file generated in the previous step. Inside the `initialize` method, you can define the roles and abilities for your application.
```
class Ability
  include CanCan::Ability
  def initialize(user)
    if user.super_admin?
      can :manage, :all
    elsif user.admin?
      can :read, Company, user_id: user.id
      can :destroy, Company, user_id: user.id
    elsif user.manager?
      can :read, Company, user_id: user.id
      can :update, Company, user_id: user.id
    elsif user.collaborator?
      can :read, Company, user_id: user.id
    end
  end
end
```
Now, assuming your User model has a `role` attribute (string or integer) to store the role, you can assign a role to the user you created. For example, if you have an `admin` role, you can run the following command to assign that role in rails console.
```
user.update(role: 'admin')
```

## Rate limiting
Open your Gemfile and add the following line:
`gem 'rack-attack'`

Save the file and run `bundle install` to install the gem.

Open your `config/application.rb` file and add the following line inside the `class Application < Rails::Application` block:
```config.middleware.use Rack::Attack```
This ensures that Rack::Attack middleware is used in your Rails application.

Put the following code inside `../config/initializers/rack_attack.rb`. Use it as template.
```
class  Rack::Attack

Rack::Attack.cache.store  =  ActiveSupport::Cache::MemoryStore.new

  throttle('api/ip', limit:  3, period:  10) do |req|
    if  req.path.match?(/^\/api\/v1\/companies$/i) &&  req.get?
      req.ip
    elsif  req.path.match?(/^\/api\/v1\/companies\/\d+$/) &&  req.patch?
      req.ip
    elsif  req.path.match?(/^\/api\/v1\/companies\/\d+$/) &&  req.delete?
      req.ip
    end
  end
end
```
