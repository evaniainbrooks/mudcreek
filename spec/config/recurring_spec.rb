require "rails_helper"

RSpec.describe "config/recurring.yml" do
  let(:config) do
    path = Rails.root.join("config/recurring.yml")
    YAML.safe_load(ERB.new(File.read(path)).result, permitted_classes: [Symbol], symbolize_names: false)
  end

  let(:tasks) do
    env_tasks = config[Rails.env.to_s] || {}
    env_tasks.map do |key, options|
      SolidQueue::RecurringTask.from_configuration(key, **options.symbolize_keys)
    end
  end

  it "has at least one task defined for the production environment" do
    production_tasks = (config["production"] || {})
    expect(production_tasks).not_to be_empty
  end

  it "all tasks have valid schedules" do
    invalid = tasks.reject(&:valid?).map do |task|
      "#{task.key}: #{task.errors[:schedule].join(', ')}"
    end
    expect(invalid).to be_empty, "Invalid recurring tasks:\n#{invalid.join("\n")}"
  end

  it "all tasks have a command or job class" do
    invalid = tasks.reject(&:valid?).map do |task|
      "#{task.key}: #{task.errors[:base].join(', ')}"
    end
    expect(invalid).to be_empty, "Tasks missing command/class:\n#{invalid.join("\n")}"
  end
end
