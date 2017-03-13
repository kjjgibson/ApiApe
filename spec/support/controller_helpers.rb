module ControllerHelpers

  def response_body
    return JSON.parse(response.body, symbolize_names: true)
  end

end