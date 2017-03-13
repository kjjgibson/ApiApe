require 'rails_helper'

# Integration specs for ApeControllerAdditions and ControllerResources
# We use a dummy Blog model and BlogsController so that we can test end-to-end
describe BlogsController do

  render_views

  let(:fields) { 'title,description' }
  let(:request_params) { { fields: fields } }
  let!(:blog) { Blog.create(title: 'Title1', description: 'Description1') }
  let!(:blog2) { Blog.create(title: 'Title2', description: 'Description2') }

  before :each do
    request.env["HTTP_ACCEPT"] = 'application/json'
  end

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

      context 'order ascending' do
        it 'should return the correct order' do
          get :index, fields: fields, order: 'title(asc)'

          expect(assigns(:blogs)).to eq([blog, blog2])
        end
      end

      context 'order descending' do
        it 'should return the correct order' do
          get :index, fields: fields, order: 'title(desc)'

          expect(assigns(:blogs)).to eq([blog2, blog])
        end
      end

      context 'order by a column that doesn\'t exist' do
        it 'should return the default order' do
          get :index, fields: fields, order: 'wrong_column(asc)'

          expect(assigns(:blogs)).to eq([blog, blog2])
        end
      end

      context 'order with an invalid sort direction' do
        it 'should return the default order' do
          get :index, fields: fields, order: 'title(wrong_order)'

          expect(assigns(:blogs)).to eq([blog, blog2])
        end
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

          expect(response_body).to eq({ data:
                                            [{ title: 'Title1', description: 'Description1' },
                                             { title: 'Title2', description: 'Description2' }] })
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

    context 'with nested permitted_fields' do
      let(:fields) { 'title,posts{content}' }

      # Update the BlogsControllerClass so that it calls render_ape with permitted fields
      controller(BlogsController) do
        render_ape permitted_fields: [:title, posts: :content]
      end

      before do
        Post.create(content: 'Post1 Content', blog: blog, created_at: Date.current - 2.days)
        Post.create(content: 'Post2 Content', blog: blog, created_at: Date.current - 1.day)
        controller.instance_variable_set(:@blog, blog)
      end

      describe '#show' do
        context 'with no ordering' do
          it 'should return the posts in the default order' do
            get :show, id: blog.id, fields: fields

            expect(response_body).to eq({ title: blog.title, posts: [
                { content: 'Post1 Content' },
                { content: 'Post2 Content' }
            ] })
          end
        end

        context 'with an ordering' do
          let(:fields) { 'title,posts{content}.order(reverse_chronological)' }

          it 'should return the posts in the correct order' do
            get :show, id: blog.id, fields: fields

            expect(response_body).to eq({ title: blog.title,
                                          posts: [
                                              { content: 'Post2 Content' },
                                              { content: 'Post1 Content' }
                                          ] })
          end
        end
      end
    end


    context 'with metadata param' do
      # Update the BlogsControllerClass so that it calls render_ape
      controller(BlogsController) do
        render_ape
      end

      let(:metadata) { { fields: ['id', 'title', 'description', 'content', 'created_at', 'updated_at'],
                         associations: ['posts'] } }

      context 'with fields param also' do
        describe '#show' do
          before do
            controller.instance_variable_set(:@blog, blog)
          end

          it 'should render the correct json' do
            get :show, id: blog.id, fields: fields, metadata: 'true'

            expect(response_body).to eq({ title: blog.title, description: blog.description,
                                          metadata: metadata })
          end
        end

        describe '#index' do
          before do
            controller.instance_variable_set(:@blogs, [blog, blog2])
          end

          it 'should render the correct json' do
            get :index, fields: fields, metadata: 'true'

            expect(response_body).to eq({ data:
                                              [{ title: blog.title, description: blog.description },
                                               { title: blog2.title, description: blog2.description }],
                                          metadata: metadata })
          end
        end
      end

      context 'without fields param' do
        describe '#show' do
          before do
            controller.instance_variable_set(:@blog, blog)
          end

          it 'should render the correct json' do
            get :show, id: blog.id, metadata: 'true'

            expect(response_body).to eq({ title: blog.title, description: blog.description,
                                          metadata: {
                                              fields: ['id', 'title', 'description', 'content', 'created_at', 'updated_at'],
                                              associations: ['posts'] } })
          end
        end

        describe '#index' do
          before do
            controller.instance_variable_set(:@blogs, [blog, blog2])
          end

          it 'should render the correct json' do
            get :index, metadata: 'true'

            expect(response_body).to eq({ data:
                                              [{ title: blog.title },
                                               { title: blog2.title }],
                                          metadata: metadata })
          end
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

        expect(response_body).to eq({ data:
                                          [{ title: 'Title1', description: 'Description1' },
                                           { title: 'Title2', description: 'Description2' }] })
      end
    end
  end

end