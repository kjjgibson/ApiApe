class ExampleController < ApplicationController

  include ApiApe::ApeController

  permitted_fields [:name, :description]

  def show
    @model = Model.find(params[:id])

    render_ape(@model)
  end

end