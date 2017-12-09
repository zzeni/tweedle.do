<a name="a-simple-tweeting-app">

# A Simple Tweeting App

A _step-by-step_ **tutorial** on how to implement a simple **Ruby on Rails** _web application_ that functions similarly to [Tweeter](https://twitter.com)

## Table of Contents
1. [Task](#task)
2. [Creation Instructions](#creation-instructions)
   - [Initialization](#initialization)
   - [Models](#models)
      - [Database](#models-1)
      - [Attached image](#models-2)
      - [Associations](#models-3)
   - [Routes](#routes)
   - [Views](#views)
      - [Landing page](#landing-page)
         - [Removing the links to nonexisting paths](#landing-1)
         - [Sample data generation](#landing-2)
         - [Design & Layout](#landing-3)
         - [Paging](#landing-4)
         - [Refactor the tweets#index](#landing-5)
         - [Displaying the author](#landing-6)
      - [General navigation and session screens](#general-navigation-and-session-screens)
         - [Navigation](#nav-sess-1)
         - [Session screens](#nav-sess-2)
      - [Users#show](#usersshow)
      - [Users#index](#usersindex)
         - [Limiting the access](#usersindex-1)
         - [Updating the view](#usersindex-1)
      - [Users#edit](#usersedit)
      - [Users#destroy](#usersdestroy)
      - [Tweets#new](#tweetsnew)
      - [Tweets#edit & tweets#destroy](#tweetsedit--tweetsdestroy)
   - [Paging with AJAX](#paging-with-ajax)

## Task

Make a web application with **Ruby on Rails** that functions similarly to [Tweeter](https://twitter.com)

You will need to implement only two models: **tweets** and **users**

A **tweet** will have `body` column of type **string**, which can't be NULL.

A **user** will have:
- a `name` column, that can't be NULL and that has a DB index (for better search performance)
- an `avatar` (attached image) with sizes: **100x100** for *thumbnali* and **300x300** for *medium* size picture

You must implement **authentication** for the **user** and add appropriate restrictions.
_You may try to authenticate the user with an **username** instead of **email**_

On your app's **website**, you should be showing:
- _all the tweets_ at the **landing** page, where each **tweet** links to it's **author** (`tweets/index`)
- **login** and **signup** screens
- a **users index** page (`users/index`)
- a **user profile** screen (`users/show`)
- an **edit user** screen, which is available only for _logged in user_ who is _the owner_ of the profile (`users/edit`)
- a **new tweet** screen, which is available only for _logged in users_ (`tweets/new`)
- an **edit tweet** screen, which is available only for _logged in user_ who is _the owner_ of the tweet (`tweets/edit`)
- a screen with *all tweets of a user* (`/users/5/tweets`)

You should also provide a `delete` action for a **tweet**, which can be _only_ performed by the _owner of the **tweet**_.

[back to top](#a-simple-tweeting-app)

## Creation Instructions

### Initialization

I've picked **tweedle.do** as a name of the app.

After I create it with `rails new`, I'll create a new _repository_ in my **Github** account and connect it to the project.

```
rails new tweedle.do -T
cd tweedle.do
git commit -m"Initial commit"
```

### Models

<a name="models-1"></a>
1. **Database**

   Add the following gems to **Gemfile**: [devise](https://github.com/plataformatec/devise), [paperclip](https://github.com/thoughtbot/paperclip), [faker](https://github.com/stympy/faker), [fabrication](https://github.com/paulelliott/fabrication), [pry-rails](https://github.com/rweng/pry-rails), [bootstrap 4](https://github.com/twbs/bootstrap-rubygem) and `jquery-rails`

   Make sure you put the new gems in their _corresponding_ groups in the **Gemfile**.

   ```
   gem 'devise', '~> 4.3.0'
   gem 'paperclip', '~> 5.1.0'
   gem 'bootstrap', '~> 4.0.0.beta2.1'
   gem 'jquery-rails', '~> 4.3.1'

   ...

   group :development, :test do
     gem 'fabrication'
     gem 'faker', :git => 'https://github.com/stympy/faker.git', :branch => 'master'
   end

   ...

   group :development do
     gem 'pry-rails'
   end
   ```

   Now let's remove the `jbuilder` gem, in order to skip the `jbuilder` generators (will omit the `JSON` format **views** when using `rails generate scaffold`).

   Then install them with **bundle**:

   ```
   bundle install
   ```

   Now it's time to generate your resources:

   ```
   rails g scaffold user name:string
   rails g scaffold tweet body:string user:belongs_to
   rails g devise:install
   rails g devise user
   rails g paperclip user avatar
   ```

   **Very important step**:

   **Review** all the generated **migration files** and **edit** them (if necessary).

   It will be a good idea to:
   - add an **index** for the **name** column in `users` table.
   - set to `not null` the **name** in `users` and the **body** in `tweets`.
   - remove all unnecessary stuff from the **devise** migration (you will use only the following devise modules: _database_authenticatable_, _registerable_, _recoverable_, _rememberable_, _trackable_, _validatable_)

   Now you can execute all migrations:

   ```
   rails db:migrate
   ```

   [back to top](#a-simple-tweeting-app)

<a name="models-2"></a>
1. **Attached image**

   Add the **Paperclip** stuff to the **User**:

   ```ruby
   has_attached_file :avatar,
                     styles: { medium: "300x300#", thumb: "100x100#" },
                     default_url: ":style/missing.png"

   validates_attachment :avatar,
                        content_type: { content_type: "image/jpeg" },
                        size: { in: 0..2.megabytes }
   ```

   Add the two **missing.png** images in the corresponding folders.

   [back to top](#a-simple-tweeting-app)

<a name="models-3"></a>
1. **Associations**

   Add the following associations to the **User** & **Tweet** models:

   ```ruby
   class User < ApplicationRecord
     has_many :tweets, dependent: :destroy
   end

   class Tweet < ApplicationRecord
     belongs_to :user
     end
   ```

   [back to top](#a-simple-tweeting-app)

### Routes

Configure the routing (in `config/router.rb`)

```ruby
Rails.application.routes.draw do
  devise_for :users

  resources :tweets, only: :index

  resources :users, only: [:index, :show, :edit, :update, :destroy] do
    resources :tweets
  end

  root to: "tweets#index"
end
```

and start your server:

```
rails s -p 3056
```

[back to top](#a-simple-tweeting-app)

### Views

#### Landing page

The **landing page** for our app is the **tweets index** page. Let's go and see _how_ it looks like.

Open your app's initial page (http://localhost:3056/). You'll get _errors_, because we've limited the **tweets routes** to _only_ **index**.

<a name="landing-1"></a>
1. **Removing the links to nonexisting paths**

   Edit `app/views/tweets/index.html.erb`:

   ```html
   <h1>Tweets</h1>

   <table>
     <thead>
       <tr>
         <th>Body</th>
         <th>User</th>
         <th colspan="3"></th>
       </tr>
     </thead>

     <tbody>
       <% @tweets.each do |tweet| %>
         <tr>
           <td><%= tweet.body %></td>
           <td><%= tweet.user %></td>
         </tr>
       <% end %>
     </tbody>
   </table>
   ```

   Now if you reload the website, you will see an empty tweets page.

   [back to top](#a-simple-tweeting-app)

<a name="landing-2"></a>
1. **Sample data generation**

   Let's generate some fake data, using **Fabrication** and **database seeds**.

   ```
   rails g fabrication:model user
   rails g fabrication:model tweet
   ```

   Edit the two generated files:

   ```ruby
   # spec/fabricators/user_fabricator.rb
   Fabricator(:user) do
     name { Faker::LordOfTheRings.unique.character }
     email { Faker::Internet.unique.email }
     password "123456"
   end
   ```

   ```ruby
   # spec/fabricators/tweet_fabricator.rb
   Fabricator(:tweet) do
     body { Faker::Lorem.paragraph(3) }
   end
   ```

   In `db/seeds.rb` put this:

   ```ruby
   User.destroy_all # will delete all users and all their tweets

   20.times do |i|
     user = Fabricate(:user)
     rand(10).times do
       Fabricate(:tweet, user: user)
     end
     puts "Generated #{user.name} with #{user.tweets.count} tweets"
   end
   ```

   Now run `rails db:seed`

   You should see something like:

   ```
   Generated Frodo Baggins with 7 tweets
   Generated Barliman Butterbur with 1 tweets
   Generated Shelob with 2 tweets
   Generated Denethor with 2 tweets
   Generated Peregrin Took with 4 tweets
   Generated Legolas with 8 tweets
   Generated Glorfindel with 3 tweets
   Generated Faramir with 6 tweets
   Generated Éomer with 2 tweets
   Generated Quickbeam with 8 tweets
   Generated Samwise Gamgee with 8 tweets
   Generated Beregond with 9 tweets
   Generated Tom Bombadil with 8 tweets
   Generated Meriadoc Brandybuck with 7 tweets
   Generated Galadriel with 8 tweets
   Generated Shadowfax with 4 tweets
   Generated Théoden with 3 tweets
   Generated Gimli with 1 tweets
   Generated Éowyn with 9 tweets
   Generated Treebeard with 7 tweets
   ```

   Now if you **reload** the website in the browser, you'll see the **Tweets** page _full of data_.

   [back to top](#a-simple-tweeting-app)

<a name="landing-3"></a>
1. **Design & Layout**

   Now it's time to fix the design.

   Let's start by setting up the **bootstrap gem**. There are just a few _easy to follow_ steps, described [here](https://github.com/twbs/bootstrap-rubygem#a-ruby-on-rails).

   So, we basically have to rename `app/assets/stylesheets/application.css` to `app/assets/stylesheets/application.scss` and replace it's contents with:

   ```scss
   @import "bootstrap";
   @import "scaffolds";
   @import "users";
   @import "tweets";
   ```

   Since we have the all these nice **Bootstrap** CSS styles now, we can remove _all the content_ in `app/assets/stylesheets/scaffolds.scss` and just leave it _empty_.

   Next we'll _replace_ the content of `app/views/tweets/index.html.erb` with the following:

   ```erb
   <h1 class="mb-4">Tweets</h1>

   <section class="tweets">
     <% @tweets.each do |tweet| %>
       <div class="card mb-3 border-primary">
         <div class="card-header">
          <%= l(tweet.created_at, format: :short) %>
         </div>
         <div class="card-body">
           <blockquote class="blockquote mb-0">
            <p><%= tweet.body %></p>
            <footer class="small text-muted">-- <%= link_to tweet.user.name, tweet.user %></footer>
           </blockquote>
         </div>
       </div>
     <% end %>
   </section>
   ```

   And in `app/views/layouts/application.html.erb` with the following:
   ```erb
   <!DOCTYPE html>
   <html>
   <head>
     <title>TweedleDo</title>
     <%= csrf_meta_tags %>

     <%= stylesheet_link_tag    'application', media: 'all', 'data-turbolinks-track': 'reload' %>
     <%= javascript_include_tag 'application', 'data-turbolinks-track': 'reload' %>
   </head>

   <body>
     <div class="container mt-5">

     <% flash.each do |name, msg| %>
      <%= content_tag(:div, msg, class: "alert alert-#{name == 'notice' ? 'info' : 'danger'}") %>
     <% end %>

     <%= yield %>

     <footer class="footer">
      <p>© The Tweet Monsters 2017</p>
     </footer>
     </div>
   </body>
   </html>
   ```

   In the **TweetsController** we'll change the **index** method like so:

   ```ruby
   def index
     @tweets = Tweet.eager_load(:user).all
   end
   ```

   Thus the **tweets** and **users** data will be loaded _altogether_ and _will save_ some extra calls to the **database** when accessing the **user** through the **tweet** (`tweet.user`).

   Now it's time to check what we've achieved and **refresh** the website.

   [back to top](#a-simple-tweeting-app)

<a name="landing-4"></a>
1. **Paging**

   You might have noticed, that we've ended up with _quite some many_ tweets and a _scroll-y_ page. What we need is **pagination**.

   In order to do so, we'll add the [kaminari](https://github.com/kaminari/kaminari) gem to our **Gemfile** and install it with `bundle install`.

   Now we need to do the following changes to the **tweets**:

   1. Change the `index` action in `TweetsController`:

      ```ruby
      def index
        @tweets = Tweet.eager_load(:user).page(params[:page]).per(3)
      end
      ```

    1. Add the following line at the end of `app/views/tweets/index.html.erb`:

       ```erb
       <%= paginate @tweets, window: 1, outer_window: 1 %>
       ```

   As a result, we can see now our **tweets** in _chunks of 3_ and fully _navigable_ via _a bunch of paging links_.

   Finally, let's make the _paging links_ bit more _stylish_.

   All we need to do is run:

   ```
   rails g kaminari:views bootstrap4
   ```

   This will generate the **kaminari** views into our `app/views` folder and add a decent _bootstrap 4_ style to the **pagination**.

   _**Note**_: As you may find in the `kaminari`'s documentation, there is a way to make the paging use **AJAX** calls instead of _hardcore_ page reloads. Although it's said to be working _just out of the box_, actually it doesn't (or it may not, which was my case). Therefore, I'm going to dedicate the final chapter of this tutorial to it.

   [back to top](#a-simple-tweeting-app)

<a name="landing-5"></a>
1. **Refactor the tweets#index**

   We'll start with a little **refactoring**.

   Let's create a new file `app/views/tweets/_tweet.html.erb` and put inside the _html_ for the **tweet**, which we used in `app/views/tweets/index.html.erb`:

   ```erb
   <div class="card mb-3 border-primary">
     <div class="card-header">
       <%= l(tweet.created_at, format: :short) %>
     </div>
     <div class="card-body">
       <blockquote class="blockquote mb-0">
         <p><%= tweet.body %></p>
         <footer class="small text-muted">-- <%= link_to tweet.user.name, tweet.user %></footer>
       </blockquote>
     </div>
   </div>
   ```

   And in `app/views/tweets/index.html.erb`, we'll replace it with just `<%= render tweet %>`.

   Now `app/views/tweets/index.html.erb` should look like:

   ```erb
   <h1 class="mb-4">Tweets</h1>

   <section class="tweets">
     <% @tweets.each do |tweet| %>
       <%= render tweet %>
     <% end %>
   </section>

   <%= paginate @tweets, window: 1, outer_window: 1 %>
   ```

   If we check what happens in the browser, we'll see that _all still works_ like a charm.

   Finally, we can do a bit more _refactoring_ and leave `app/views/tweets/index.html.erb` like this:

   ```erb
   <h1 class="mb-4">Tweets</h1>

   <section class="tweets">
     <%= render @tweets %>
   </section>

   <%= paginate @tweets, window: 1, outer_window: 1 %>
   ```

   The reason it works is - **rails** is just _incredibly helpful_ and always does it's best to ease us. _Neat, huh! :)_

   <a name="landing-6"></a>
   1. **Displaying the author**

   Now as we're done with the refactoring, we're ready to add some new code to `app/views/tweets/_tweet.html.erb`:

   ```erb
     ...
     <div class="card-body d-flex">
       <div class="avatar-holder rounded-circle border align-self-baseline mr-4">
         <%= image_tag tweet.user.avatar.url(:thumb), alt: "#{tweet.user.name} image" %>
       </div>
       ...
     </div>
   ```

   _Just don't forget to add the `d-flex` class to the `card-body` ;)_

   And that's _all_ we need. Now our **home** page (**tweets index**) is _complete_.

   [back to top](#a-simple-tweeting-app)

#### General navigation and session screens

<a name="nav-sess-1"></a>
1. Navigation

   In order to allow us to _access_ every page in our app, we need to add **navigation** to the main _application_ view.

   We'll make it in a new partial under the `app/views/layouts/` folder, named `_header.html.erb`.

   It's content will be just a reworked **Bootstrap 4** template, copied from [here]](https://getbootstrap.com/docs/4.0/components/navbar/#supported-content).

   Here's how the new `app/views/layouts/_header.html.erb` file will look like:

   ```erb
   <header class="mb-5">
     <nav class="navbar navbar-expand-lg navbar-light bg-info">
       <%= link_to 'Tweedle.do', root_path, class: 'navbar-brand text-white' %>
       <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarSupportedContent" aria-controls="navbarSupportedContent" aria-expanded="false" aria-label="Toggle navigation">
         <span class="navbar-toggler-icon"></span>
       </button>

       <div class="collapse navbar-collapse" id="navbarSupportedContent">
         <ul class="navbar-nav mr-auto">
           <% if current_user %>
             <li class="nav-item">
               <%= link_to 'New tweet', new_user_tweet_path(current_user), class: 'btn btn-outline-light my-2 my-sm-0' %>
             </li>
           <% end %>
         </ul>

         <ul class="navbar-nav ml-auto">
           <li class="nav-item">
             <%= link_to 'Home', root_path, class: 'nav-link' %>
           </li>
           <% if current_user %>
             <li class="nav-item">
               <%= link_to 'My profile', current_user, class: 'nav-link' %>
             </li>
             <li class="nav-item">
               <%= link_to 'Log out', destroy_user_session_path, method: :delete, class: 'nav-link' %>
             </li>
           <% else %>
             <li class="nav-item">
               <%= link_to 'Sign up', new_user_registration_path, class: 'nav-link' %>
             </li>
             <li class="nav-item">
               <%= link_to 'Log in', new_user_session_path, class: 'nav-link' %>
             </li>
           <% end %>
         </ul>
       </div>
     </nav>
   </header>
   ```

   With the code above, we're making **links** to the _login/logout_ screens, the _current user's profile_, etc.

   Next, we need to "import" the header in the main _application_ view (i.e. to **render** it there). We'll also _change a bit_ the HTML markup in it's `body` element, like so:

   ```
   ...
   <body>
     <div class="container d-flex flex-column" id="main-container">
       <main>
         <% flash.each do |name, msg| %>
             <%= content_tag(:div, msg, class: "alert alert-#{name == 'notice' ? 'info' : 'danger'}") %>
         <% end %>

         <%= yield %>
       </main>

       <footer class="footer mt-auto">
         <hr>
         <p>© The Tweet Monsters 2017</p>
       </footer>
     </div>

     <%= render 'layouts/header' %>
   </body>
   ...
   ```

   Notice that we've put the `header` partial at the end of `body` element. The reason is, that it will be a _fixed_ element (through the CSS), which makes it stay on the top of other element and not scroll. In order to achieve that, we need to make some SCSS styles, but we also need it to be the last element in `<body>`.

   Speaking of CSS, here's what we'll **add** to our `app/assets/stylesheets/application.scss`:

   ```scss
   @import "bootstrap";
   @import "scaffolds";
   @import "users";
   @import "tweets";

   html, body, #main-container {
     height: 100%;
   }

   header {
     position: fixed;
     left: 0;
     right: 0;
     top: 0;

     .navbar.bg-info .navbar-nav .nav-link {
       color: rgba(255, 255, 255, .85);

       &:hover {
         color: #fff;
       }
     }
   }

   body {
     padding-top: 80px;
   }
   ```

   [back to top](#a-simple-tweeting-app)

 <a name="nav-sess-2"></a>
1. Session screens

   Maybe you've already tried to _sign up_ and it _didn't work_.

   The reason is simple - the generic _devise_ view for the user's _registration_, doesn't have a `name` field, but the `name` property of the user is _obligatory_ in our database.

   That means we must fix **two things**:

   - add some _reasonable_ **validations** to our **models** in order to avoid **database errors**
   - _override_ the generic **devise** views in order to add the `name` field to the **sign up form**

   First we'll start with the _model validations_. We just need to add the following two lines to `app/models/user.rb`:

   ```ruby
   validates :name, presence: true
   validates :email, uniqueness: true
   ```

   In order to _override_ the **devise** views, we need to _bring them up_ inside the application.

   This can be done with the following _generator_:

   ```
   rails g devise:views
   ```

   You will notice that a bunch of _devise files_ were added to our `app/views/` folder.

   You have the _option_ whether to _leave_ all of them there, or just keep the `app/views/devise/registrations/new.html.erb` (_the one_ we want to _change_) and _delete the rest_.

   And here's how we want to change `app/views/devise/registrations/new.html.erb`:

   ```erb
   ...

   <%= devise_error_messages! %>

   <div class="field">
     <%= f.label :name %><br />
     <%= f.text_field :name, autofocus: true %>
   </div>

   ...
   ```

   We may also want to change _the style_ of the _form_ later, but only thing we'll do now is to add this SCSS to the `app/assets/stylesheets/scaffolds.scss`:

   ```scss
   .field {
     margin: 1em 0;
   }
   ```

   One final change _we must_ do (_the sign up is not working yet_) is to _allow_ the `name` parameter be sent altogether with the rest devise parameters.

   In order to do that, we need to add to our `ApplicationController` these lines:

   ```
   ...
   before_action :configure_permitted_parameters, if: :devise_controller?

   protected

   def configure_permitted_parameters
     devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :email, :password, :password_confirmation])
   end
   ...
   ```

   Now if we try to **sign up** again, we'll finally succeed, but we'll be _immediately_ thrown into _a new error_: `undefined local variable or method `new_user_path'`. Apparently it's time to _re-work_ our **users** views..

   [back to top](#a-simple-tweeting-app)

#### Users#show
   It's _finally_ time to get our hands on the **user views**.

   We'll start from the **show** view and we'll just _paste_ inside the following code:

   ```erb
   <div class="d-lg-flex mt-3">
     <section class="left mr-lg-5 mb-5">
       <h1 class="mb-3"><%= @user.name %>'s Profile</h1>

       <div class="card border-primary user my-3">
         <%= image_tag @user.avatar.url(:medium), class: "card-image-top rounded-circle bg-light" %>
         <div class="card-header bg-info text-white">
           <%= @user.name %>
         </div>
         <div class="card-body">
           <ul>
             <li class="my-2"><strong>Total tweets:</strong> <%= @user.tweets.count %></li>
             <li class="my-2"><strong>Total in the last week:</strong> <%= @user.tweets.where('created_at > ?', 1.week.ago).count %></li>
             <li class="my-2"><strong>Email:</strong> <%= @user.email %></li>
           </ul>

         </div>
           <% if @user == current_user %>
             <div class="btn-group d-flex">
               <%= link_to 'Edit', edit_user_path(@user), class: 'btn btn-info col-sm-6' %>
               <%= link_to 'Back', users_path, class: 'btn btn-secondary col-sm-6 ml-0' %>
             </div>
           <% else %>
             <%= link_to 'Back', users_path, class: 'btn btn-secondary btn-block' %>
           <% end %>
       </div>
     </section>

     <section class="right">
       <h2 class="mb-5"><%= @user.name %>'s tweets</h2>

       <%= render @user.tweets %>
     </section>
   </div>
   ```

   And here's _a minimalistic_ SCSS touch in `app/assets/stylesheets/users.scss`:

   ```scss
   .user.card .card-image-top {
     max-width: 300px;
     margin: 1em auto;
   }

   @media only screen and (min-width: map-get($grid-breakpoints, sm)) {
     .user.card {
       width: 300px;

       .card-image-top {
         margin: 0;
       }
     }
   }
   ```

   The _first change_ uses lots of **Bootstrap 4** classes in order to make a nice _layout_ for the `users#index` page. While the _second change_, only _polished_ what we've already achieved with _Bootstrap_, in order to make the _layout_ even more _responsive_.

   _Finally_, we'll make it even nicer, by adding **pagination** for the user's **tweets**.

   First we'll change the **show** method in `UsersController`:

   ```ruby
   ...
   def show
     @tweets = @user.tweets.page(params[:page]).per(5)
   end
   ...
   ```

   And then in `app/views/users/show.html.erb` we'll just add this piece of code:

   ```erb
   <%= paginate @tweets %>
   ```

   _right under_ the `<%= render @tweets %>` line.

   .. and **we're done**! :)

   [back to top](#a-simple-tweeting-app)

#### Users#index

<a name="usersindex-1"></a>
1. **Limiting the access**

   _Similarly_ to the **tweets#index** the users **index view** _shows an error_, because it contains links to _paths that are not routed_ (like the link to the **users#new**: `<%= link_to 'New User', new_user_path %>`).

   If we **remove** the failing link, the page will load successfully, but we may notice, that the **edit** and **destroy** actions are *accessible* even though we're currently **not logged in**.

   This can be fixed in our `UsersController`, by adding the following **before action**:

   ```ruby
   before_action :authenticate_user!, except: [:show, :update]
   ```

   The `authenticate_user!` method is a `helper method` that comes with **devise** gem and is achieved via the *method_missing* magic.

   So now, we're _no longer be able_ to **edit** or **delete** any **user**, without being _logged in_.

   But _that's not enough_.

   Imagine that you're _logged in your profile_ (you can use _any_ of the generated _fake users_ with a password `123456` or just _sign up_ a new user). Does this mean that you should be able to _change_ or _delete_ other users profiles ? Well, of course _no_.

   In order to fix that, we need to add _yet another restriction_ in `UsersController`

   ```ruby
   class UsersController < ApplicationController
     before_action :authenticate_user!, except: [:show, :index]
     before_action :set_user, only: [:show, :edit, :update, :destroy]
     before_action :authenticate_owner!, except: [:show, :index]

     ...

     private
     ...

     def authenticate_owner!
      return if current_user == @user
      flash[:alert] = "This action is not allowed"
      redirect_back fallback_location: root_path
     end
   end
   ```

   And that is _enough_. If you _login_ now, you'll see that you can **edit/delete** only _your own account_.

   <a name="usersindex-2"></a>

1. **Updating the view**

   Let's create a _user partial_, the same way we did it for the `tweets#index`.

   It will be a **new** file, named `app/views/users/_user.html.erb`.

   Inside, we'll put the _**.card**_ element from the `users#show` view, an make a couple of _slight modifications_ in it like:

   - changing the `@user` _variable_ to the `user` _local assign_
   - changing the _static **back** link_ to a _dynamic link_, that takes it's text and path from the _local assign_ `links_to`

   Here you can see the result code:

   ```erb
   <div class="card border-primary user my-3">
     <%= image_tag user.avatar.url(:medium), class: "card-image-top rounded-circle bg-light" %>
     <div class="card-header bg-info text-white">
       <%= user.name %>
     </div>

     <div class="card-body">
       <ul>
         <li class="my-2"><strong>Total tweets:</strong> <%= tweets.count %></li>
         <li class="my-2"><strong>Total in the last week:</strong> <%= tweets.where('created_at > ?', 1.week.ago).count %></li>
         <li class="my-2"><strong>Email:</strong> <%= user.email %></li>
       </ul>
     </div>

     <% if user == current_user %>
       <div class="btn-group d-flex">
         <%= link_to 'Edit', edit_user_path(user), class: 'btn btn-info col-sm-6' %>
         <%= link_to links_to[:text], links_to[:path], class: 'btn btn-secondary col-sm-6 ml-0' %>
       </div>
     <% else %>
       <%= link_to links_to[:text], links_to[:path], class: 'btn btn-secondary btn-block' %>
     <% end %>
   </div>
   ```

   Next, we'll need to change the _content_ of the `index` view as well:

   ```erb
   <h1>Users</h1>

   <div class="users-grid d-flex flex-wrap justify-content-between">
     <% @users.each do |user| %>
       <%= render user, links_to: { text: 'show', path: user } %>
     <% end %>
   </div>
   ```

   If you _refresh_ the `users#index` page now, you'll see that it already looks a lot better.

   Since we have _duplicating code_ in `app/views/users/show.html.erb` and `app/views/users/_user.html.erb`, we'll do a little **refactoring**, by removing the duplicated code from `app/views/users/show.html.erb` and **rendering** the new _partial_ on it's place.

   ```erb
   <div class="d-lg-flex mt-3">
     <section class="left mr-lg-5 mb-5">
       <h1 class="mb-3"><%= @user.name %>'s Profile</h1>
       <%= render @user, links_to: { text: 'Back', path: users_path } %>
     </section>

     <section class="right">
       <h2 class="mb-5"><%= @user.name %>'s tweets</h2>

       <%= render @tweets %>

       <%= paginate @tweets %>
     </section>
   </div>
   ```

   As a _last step_, we will add **paging** on the `users#index` page. To do so, we have to change the `index` method in `UsersController`:

   ```ruby
     def index
       @users = User.page(params[:page]).per(6)
     end
   ```

   and add the _pagination_ helper in the **index** view:

   ```erb
   <h1>Users</h1>

   <div class="users-grid d-flex flex-wrap justify-content-between">
     <% @users.each do |user| %>
       <%= render user, tweets: user.tweets, links_to: { text: 'show', path: user } %>
     <% end %>

     <div class="align-self-end">
       <%= paginate @users %>
     </div>
   </div>
   ```

   [back to top](#a-simple-tweeting-app)

   #### Users#edit

   From the *users* actions we're only left to implement the _edit/update_ and _destroy_ actions.

   We'll start with the first two.

   First, we'll edit the views, and we'll actually _merge_ the **edit** view with the **\_form** partial, because we won't need the form to be shared (we'll also delete the **users#new** view).

   After we're done, we'll have two _deleted_ files (`app/views/users/_form.html.erb` and `app/views/users/new.html.erb`). We'll also have the following _new content_ in `app/views/users/edit.html.erb`:

   ```erb
   <h1>Edit your profile</h1>

   <%= form_with(model: @user, local: true) do |form| %>
     <% if @user.errors.any? %>
       <div id="error_explanation">
         <h2><%= pluralize(@user.errors.count, "error") %> prohibited from saving your changes:</h2>

         <ul>
         <% @user.errors.full_messages.each do |message| %>
           <li><%= message %></li>
         <% end %>
         </ul>
       </div>
     <% end %>

     <div class="form-group">
       <div class="image-preview my-4">
         <%= image_tag @user.avatar.url(:medium) %>
       </div>
       <%= form.file_field :avatar, class: 'image-input' %>
     </div>

     <div class="form-group">
       <%= form.label :name, class: 'control-label' %>
       <%= form.text_field :name, id: :user_name, class: 'form-control' %>
     </div>

     <div class="form-group">
       <%= form.label :email, class: 'control-label' %>
       <%= form.email_field :email, id: :user_email, class: 'form-control' %>
     </div>

     <div class="actions">
       <%= form.submit class: 'btn btn-primary' %>
       <%= link_to 'Cancel', @user, class: 'btn btn-secondary' %>
     </div>
   <% end %>

   <div class="my-5">
   ```

   Now you can already go the the **edit profile** page (in order to do so you _must_ **log-in** or **sign-up**) and try it out.

   You'll notice that the **update** action _doesn't work_. The reason is, that we _haven't allowed_ the `avatar` and `email` parameters in the `UsersControler`. In order to do so, we _must change_ the `user_params` method like this:

   ```ruby
   def user_params
     params.require(:user).permit(:name, :email, :avatar)
   end
   ```

   Now all should work perfectly.

   There is one _future improvement_ to be done here - an image preview of the new `avatar` image.

   [back to top](#a-simple-tweeting-app)

   #### Avatar upload preview

   I'm going to get into details here. We'll just use some **JavaScropt** code, that _just works_.

   We can place it in a new CoffeeScript file like `app/assets/javascripts/image-preview.coffee`:

   ```coffeescript
   $ ->
     $('.image-preview').on 'click', (event) ->
       $(this).parent().find('.image-input').click()

     $('.image-input').on 'change', (event) ->
       image = event.target.files[0];
       reader = new FileReader();
       target = $(this).parent().find('.image-preview img')

       target.css {opacity: 0}

       reader.onload = (file) ->
         target[0].src = file.target.result

         if target.outerWidth() > target.outerHeight()
           target.css {'max-height': '100%', 'max-width': 'initial'}
         else
           target.css {'max-width': '100%', 'max-height': 'initial'}

         target.css {opacity: 1}

       reader.readAsDataURL image
   ```

   Before it can work, we must require `jquery` in our `application.js` file. We'll use the moment to also require `bootstrap` & `popper` libraries.

   Finally, `app/assets/javascripts/application.js` should look like this:

   ```coffeescript
   //= require rails-ujs
   //= require turbolinks
   //= require jquery3
   //= require popper
   //= require bootstrap
   //= require_tree .
   ```

   Before we call it _done_, we'll add a tiny change in the SCSS too.

   We'll just add this to ``:

   ```scss
   .image-preview {
     width: 300px;
     height: 300px;
     cursor: pointer;
     display: flex;
     justify-content: center;
     align-items: center;
     overflow: hidden;
   }
   ```

   Now if we try to set an avatar for a use it works like a charm.

   _**Note:**_ The avatar images are being saved under the `public/system/` folder, whish is under a _version controll_. Since we don't want to keep track on these image files, we should add at the end of our `.gitignore` file the following:

   ```
   # ignore paperclip image files
   public/system/
   ```

   [back to top](#a-simple-tweeting-app)

   #### Users#destroy

   Giving it a second thought, the `destroy` action is not really typical for user profiles, so I'll just prohibit it from the `UsersController`:

   ```ruby
   before_action :set_user, only: [:show, :edit, :update]
   ```

   [back to top](#a-simple-tweeting-app)

#### Tweets#new

There's one big and _shiny_ button in our _main navigation_, that leads us to the **New tweet** page.

There's nothing wrong with it, but we may make it look a little nicer.

`app/views/tweets/_form.html.erb`:
```erb
<%= form_with(model: tweet, url: user_tweets_path(current_user), local: true, class: 'mt-3') do |form| %>
  <% if tweet.errors.any? %>
    <div id="error_explanation" class="my-4">
      <h2><%= pluralize(tweet.errors.count, "error") %> prohibited this tweet from being saved:</h2>

      <ul>
      <% tweet.errors.full_messages.each do |message| %>
        <li><%= message %></li>
      <% end %>
      </ul>
    </div>
  <% end %>

  <div class="form-group">
    <%= form.text_area :body, id: :tweet_body, class: 'form-control', rows: 6 %>
  </div>

  <div class="d-flex justify-content-end">
    <%= link_to 'Cancel', root_path, class: 'btn btn-outline-secondary mr-1' %>
    <button type="submit" class="btn btn-outline-primary">Create</button>
  </div>
<% end %>

```

`app/views/tweets/new.html.erb`:
```erb
<h1>New Tweet</h1>

<%= render 'form', tweet: @tweet %>
```

According to our `routes` _all tweets actions_, except for _index_, are accessible through the _user's profile_.

It means that if we want to _edit a tweet_, we must send a `POST` request to `/users/5/tweets/3`, where:

- we want to edit a **tweet with an ID 3**, which `is owned` by a **user with an id 5** (_already implemented_)
- we `must ensure` that **User#5** and **current_user** are _one and the same_ person (_pending implementation_)

The first point is already implemented, but we must remember to use only the _nested routes_ for the tweets. Therefore we pass `user_tweets_path(current_user)` url to the form.

We also should take care of properly assigning the user to the new record and limiting the access of unauthorized users.

Let's implement the pending functionality. We'll create a `before_action` method in `TweetsControler`, which will check for _ownership_:

```ruby
class TweetsController < ApplicationController
  before_action :set_user, only: [:edit, :create, :update, :destroy]
  before_action :set_tweet, only: [:edit, :update, :destroy]

  ...

  private

  ...

  def set_user
    @user = current_user
    unless @user && params[:user_id] == @user.id.to_s
      redirect_to root_path, alert: "Invalid action"
    end
  end
```

We'll also make the following changes in the _controller_:
- update the `create` action by assigning the proper user to the new tweet
- update the `create` action by redirecting to the `root_path` after successful creation
- remove the `user_id` from the _tweet params_ hash, because we get it directly from the request `url`


```ruby
def create
  @tweet = Tweet.new(tweet_params)
  @tweet.user_id = @user.id

  if @tweet.save
    redirect_to root_path, notice: 'Tweet was successfully created.'
  else
    render :new
  end
end

...

def tweet_params
  params.require(:tweet).permit(:body)
end
```

Finally we'll change the order of the tweets to make the most recent ones - first.

```ruby
def index
  @tweets = Tweet.order(created_at: 'desc').eager_load(:user).page(params[:page]).per(3)
end

```

[back to top](#a-simple-tweeting-app)

#### Tweets#edit & Tweets#destroy

We'll implement the last two actions for the **tweet** model together.

You may review a patch with the changes that are necessary for this step here:

[https://github.com/zzeni/tweedle.do/commit/3ff301cb3e9d7969b0dd3d22281bcb9d36bc01ea](https://github.com/zzeni/tweedle.do/commit/3ff301cb3e9d7969b0dd3d22281bcb9d36bc01ea)

[back to top](#a-simple-tweeting-app)


