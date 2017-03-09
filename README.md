
ApiApe
===================

ApiApe makes your APIs so easy to use that even an ape could use them.

### Table of contents

You can insert a table of contents using the marker `[TOC]`:

[TOC]

## Installation

Add this to your Gemfile: 

    gem 'api-ape'
    
and run the `bundle install` command.


## Getting Started

### Request Attribute Filtering

Request attribute filtering allows your end users to specify the attributes that they want to get back in the response body.

When designing an API you'd normally need to hardcode the response body to return everything (or a subset of things) which can limit your API.

Old (lame) way:
```
GET /posts/1
200 OK
{
	"title" : "Amazing new Api Gem",
	"description" : "Found this great new gem ApiApe...",
	"author_id" : 1,
	"comments" : [],
	#lots of other fields...
}
```

An alternative:
```
GET /posts/1?fields=title,description
200 OK
{
	"title" : "Amazing new Api Gem",
	"description" : "Found this great new gem ApiApe..."
}
```


#### I'm feeling extra lazy
In the simplest situations you can leave everything up to ApiApe. 

```
class PostsController < ApplicationController
	load_and_render_ape
	
	def show
		# The variable @post will be available here
	end

	def index
		# The variable @posts will be available here
	end
	
end
```

The above code will load your resource into an instance variable which is available at the beginning of each of your Controller actions.

After you action code is executed, the default render behaviour will take place (rending the default view). Here's comes the interesting part: if the request params contain ***'fields'*** then the default rendering behaviour is replaced by an automatic JSON render call containing only the fields that the user requested (this means that your regular view will **NOT** be rendered).

In this way, you can set up a view which renders a default set of attributes and then allow the API user to request what they want. If they don't specify what they want then they just get the default.

**But what if the user is super evil and tries bad things?**

In general it's a bad idea to let your user run wild and request any attribute they feel like. To prevent this, provide options to the *'load_and_render_ape'* call to whitelist attributes.

```
class PostsController < ApplicationController
	load_and_render_ape permitted_fields: [:title, :description, :author_id, :comments, ...]
	
	def show
	end
	
end
```

If a user requests an attribute that's not whitelisted then the rendering will continue as normal and the attribute will not be included in the response.


#### Get Your Filthy Hands off my Resources

If you don't want ApiApe to be responsible for loading your resources then replace '*load_and_render_ape*' with '*render_ape*'.

```
class PostsController < ApplicationController
	render_ape
	
	def show
		@post = Post.find(params[:id])
		# ApiApe will take care of rendering if it needs to
	end
	
end
```


#### ApiApe is Getting Too Much Action

If you don't want ApiApe to perform it's magic for every action in your controller then you can skip certain actions.

```
class PostsController < ApplicationController
	load_and_render_ape
	skip_load_resource only: :show
	skip_render_ape only: :index
	# skip_load_and_render_ape only :show
	
	def show
		@post = Post.find(params[:id])
		# ApiApe will take care of rendering if it needs to
	end

	def index
		# @posts will be avilable here
	end
	
end
```

Another option if you want total control is to call the render method manually.

```
class PostsController < ApplicationController

	def show
		@post = Post.find(params[:id])
		render_ape(@post)
	end
	
end
```

#### Nested Fields

Api consumers can request nested attributes on your models using curly braces. You can nest these as deeply as you like, e.g. *author{comments{text}}*

```
GET /posts/1?fields=title,description,author{username}
200 OK
{
	"title" : "Amazing new Api Gem",
	"description" : "Found this great new gem ApiApe...",
	"author" : {
		"username" : "Bob"
	}
}
```

### Resource Ordering

*Coming Soon*

### Introspection

*Coming Soon*

### Debug Mode

*Coming Soon*

### Pagination

*Coming Soon*

### Errors

*Coming Soon*