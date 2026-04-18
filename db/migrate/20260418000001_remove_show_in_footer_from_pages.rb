class RemoveShowInFooterFromPages < ActiveRecord::Migration[8.1]
  def change
    safety_assured { remove_column :pages, :show_in_footer, :boolean, default: false, null: false }
  end
end
