require 'api_ape/ape_controller_additions'

class BlogsController < ApplicationController

  # load_resource #Just do the resource loading
  # render_ape #Just do the rendering - looking for an appropriately named instance variable
  # load_and_render_ape permitted_fields: [:title, :description] # Do both the resource loading and rendering

  # permitted_ape_fields [:title, :description] #Permit certain fields for manual rendering

  def show
    # @blog = Blog.find(params[:id])
    # render_ape(@blog) # Manually trigger the rendering
  end

  def index
    # @blogs = Blog.all
    # render_ape(@blogs)
  end

end