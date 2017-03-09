require 'rails_helper'

# Integration specs for ControllerAdditions and ControllerResources
# We use a dummy Blog model and BlogsController so that we can test end-to-end
describe BlogsController do

  render_views

  let(:fields) { 'title,description' }
  let(:request_params) { { fields: fields } }
  let!(:blog) { Blog.create(title: 'Title1', description: 'Description1') }
  let!(:blog2) { Blog.create(title: 'Title2', description: 'Description2') }

  context 'load_resource' do
    # Update the BlogsControllerClass so that it calls load_resource
    controller(BlogsController) do
      load_resource
    end

    describe '#show' do
      it 'should assign the instance variable' do
        get :show, id: blog.id, fields: fields

        expect(assigns(:blog)).to eq(blog)
      end
    end

    describe '#index' do
      it 'should assign the instance variable' do
        get :index, request_params

        expect(assigns(:blogs)).to eq([blog, blog2])
      end
    end
  end

  context 'render_ape' do
    context 'no permitted_fields' do
      # Update the BlogsControllerClass so that it calls render_ape
      controller(BlogsController) do
        render_ape
      end

      describe '#show' do
        before do
          controller.instance_variable_set(:@blog, blog)
        end

        it 'should render the correct json' do
          get :show, id: blog.id, fields: fields

          expect(response_body).to eq({ title: blog.title, description: blog.description })
        end
      end

      describe '#index' do
        before do
          controller.instance_variable_set(:@blogs, [blog, blog2])
        end

        it 'should render the correct json' do
          get :index, request_params

          expect(response_body).to eq([{ title: 'Title1', description: 'Description1' }, { title: 'Title2', description: 'Description2' }])
        end
      end
    end

    context 'with permitted_fields' do
      # Update the BlogsControllerClass so that it calls render_ape with permitted fields
      controller(BlogsController) do
        render_ape permitted_fields: [:title]
      end

      describe '#show' do
        before do
          controller.instance_variable_set(:@blog, blog)
        end

        it 'should render the correct json' do
          get :show, id: blog.id, fields: fields

          expect(response_body).to eq({ title: blog.title })
        end
      end
    end
  end

  context 'load_and_render_ape' do
    # Update the BlogsControllerClass so that it calls load_and_render_ape
    controller(BlogsController) do
      load_and_render_ape
    end

    describe '#show' do
      it 'should assign the instance variable' do
        get :show, id: blog.id, fields: fields

        expect(assigns(:blog)).to eq(blog)
      end

      it 'should render the correct json' do
        get :show, id: blog.id, fields: fields

        expect(response_body).to eq({ title: blog.title, description: blog.description })
      end
    end

    describe '#index' do
      it 'should assign the instance variable' do
        get :index, request_params

        expect(assigns(:blogs)).to eq([blog, blog2])
      end

      it 'should render the correct json' do
        get :index, request_params

        expect(response_body).to eq([{ title: 'Title1', description: 'Description1' }, { title: 'Title2', description: 'Description2' }])
      end
    end
  end

end