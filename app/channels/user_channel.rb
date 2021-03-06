class UserChannel < ApplicationCable::Channel
  include CableReady::Broadcaster

  def subscribed
    stream_from "UserChannel#{user_id}"
  end

  def receive(data)
    data      = ActionController::Parameters.new(data)
    filter    = data[:filter] || "all"
    operation = data[:operation][:name]
    params    = data[:operation][:params] || {}
    edit_id   = params[:id].to_i if operation == "edit"

    send operation, params if respond_to?(operation, true)

    html = TodosController.renderer.render(
      template: "/todos/index",
      layout: false,
      assigns: {
        filter: filter,
        todos: Todo.owned_by(user_id).send(filter),
        completed_count: Todo.owned_by(user_id).completed.count,
        uncompleted_count: Todo.owned_by(user_id).uncompleted.count,
        edit_id: edit_id
      }
    )

    cable_ready["UserChannel#{user_id}"].morph selector: "section#todoapp", html: html
    cable_ready.broadcast
  end

  private

    def create(params)
      Todo.create params.permit(:title).merge(user_id: user_id)
    end

    def update(params)
      return toggle_all if params[:id] == "toggle"
      todo = Todo.owned_by(user_id).find_by(id: params[:id])
      todo.update params.permit(:title, :completed)
    end

    def toggle_all
      if Todo.uncompleted.present?
        Todo.owned_by(user_id).uncompleted.update_all completed: true , updated_at: Time.current
      else
        Todo.owned_by(user_id).completed.update_all completed: false, updated_at: Time.current
      end
    end

    def destroy(params)
      if params[:id] == "completed"
        Todo.owned_by(user_id).completed.destroy_all
      else
        Todo.owned_by(user_id).find(params[:id]).destroy
      end
    end
end
