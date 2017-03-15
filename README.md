ApiApe
===================

ApiApe makes your APIs so easy to use that even an ape could use them.

### Table of contents

[TOC]

## Installation

Add this to your Gemfile: 

    gem 'api-ape'
    
and run the `bundle install` command.


## Getting Started

### Request Attribute Filtering

Request attribute filtering allows your end users to specify the attributes that they want to get back in the response body.

When designing an API you'd normally need to hardcode the response body to return everything (or a subset of things) which can limit your API.

Old way:
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


#### Loading and Rendering

In the simplest situations you can leave everything up to ApiApe. Add the load_and_render_ape method to your top level ApplicationController.

```
class ApplicationController
    load_and_render_ape
end
```

Or if you want a little bit more control, add the load_and_render_ape method to your specific controller.

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

If a user requests an attribute that's not white listed then the rendering will continue as normal and the attribute will not be included in the response.


#### Rendering

If you don't want ApiApe to be responsible for loading your resources then replace '*load_and_render_ape*' with '*render_ape*'.

```
class PostsController < ApplicationController
	render_ape # permitted_fields: [:title, ...]
	
	def show
		@post = Post.find(params[:id])
		# ApiApe will take care of rendering if it needs to
	end
	
end
```


#### Skipping Loading or Rendering

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

Another option if you want total control is to call the render method manually. The _render_ape_ method also takes a hash of options where you can specify permitted_fields just like _load_and_render_ape_.

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
	"title" : "Amazing new API Gem",
	"description" : "Found this great new gem ApiApe...",
	"author" : {
		"username" : "Bob"
	}
}
```

### Resource Ordering

When providing your API consumer with a collection of objects you're often forced to choose a default ordering in which they'll receive them. This puts the burden of ordering into the hands of your API consumers. Let ApiApe do it for you.

#### Top Level Collection

When using the _load_and_render_ape_ or _render_ape_ methods, API consumers can specify an ordering using a request param.

```
GET /posts?order=title(asc)&fields=title
200 OK
[
    { "title" : "Amazing new API Gem" },
    { "title" : "Brilliant APIs" }
]
```

The collection can be ordered by any field on the object. In the case where you are specifying the permitted fields, only fields that are permitted can be used to order the collection.

### Nested Collections

It's also possible to order a nested collection when specifying nested fields. Add an order clause to the end of a collection when providing the fields request param.

The order clause takes a type which must be one of: 'chronological' or 'reverse_chronological'.

```
GET /posts/1?fields=title,comments{:message}.order(chronological)
200 OK
{
	"title" : "Amazing new API Gem",
	"comments" : [...] # Chronologically ordered list of comments
}
```

### Introspection

API Introspection allows the API consumer to navigate the API without needing to know it ahead of time or without needing to read the docs (as much).

If a request is received with a "metadata" param then the repsonse body will contain metadata about the resource.

By default the metadata will include all columns on your ActiveRecord model as well as all associations. If you've provided a list of permitted parameters then this will be used instead.

```
GET /posts/1?metadata=true&fields=title
200 OK
{
	"title" : "Amazing new API Gem",
	"metadata" : {
	    "fields" : ["title", "description", ...],
	    "associations" : ["comments", "user", ...]
	}
}
```


### Debug Mode

Debug mode adds debug information to the response body to assist an API consumer to debug their API requests.

A request with a "debug" param will trigger debug mode. The debug value must be one of: "info", "warning", or "all".

```
GET /posts/1?debug=warning&fields=title
200 OK
{
	"title" : "Amazing new API Gem",
	"__debug__" : {
	    "messages" : [
	        {
	            "message" : "Something suspicious happened...",
	            "type" : "warning"
	        }
	    ]
	}
}
```


### Pagination

*Coming Soon*

### Errors

*Coming Soon*