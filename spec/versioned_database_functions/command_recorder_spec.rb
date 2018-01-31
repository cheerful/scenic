require "spec_helper"

describe VersionedDatabaseFunctions::CommandRecorder do
  describe "#create_function" do
    it "records the created function" do
      recorder.create_function :greetings

      expect(recorder.commands).to eq [[:create_function, [:greetings], nil]]
    end

    it "reverts to drop_function" do
      recorder.revert { recorder.create_function :greetings }

      expect(recorder.commands).to eq [[:drop_function, [:greetings]]]
    end
  end

  describe "#drop_function" do
    it "records the dropped function" do
      recorder.drop_function :users

      expect(recorder.commands).to eq [[:drop_function, [:users], nil]]
    end

    it "reverts to create_function with specified revert_to_version" do
      args = [:users, { revert_to_version: 3 }]
      revert_args = [:users, { version: 3 }]

      recorder.revert { recorder.drop_function(*args) }

      expect(recorder.commands).to eq [[:create_function, revert_args]]
    end

    it "raises when reverting without revert_to_version set" do
      args = [:users, { another_argument: 1 }]

      expect { recorder.revert { recorder.drop_function(*args) } }
        .to raise_error(ActiveRecord::IrreversibleMigration)
    end
  end

  describe "#update_function" do
    it "records the updated function" do
      args = [:users, { version: 2 }]

      recorder.update_function(*args)

      expect(recorder.commands).to eq [[:update_function, args, nil]]
    end

    it "reverts to update_function with the specified revert_to_version" do
      args = [:users, { version: 2, revert_to_version: 1 }]
      revert_args = [:users, { version: 1 }]

      recorder.revert { recorder.update_function(*args) }

      expect(recorder.commands).to eq [[:update_function, revert_args]]
    end

    it "raises when reverting without revert_to_version set" do
      args = [:users, { version: 42, another_argument: 1 }]

      expect { recorder.revert { recorder.update_function(*args) } }
        .to raise_error(ActiveRecord::IrreversibleMigration)
    end
  end

  describe "#replace_function" do
    it "records the replaced function" do
      args = [:users, { version: 2 }]

      recorder.replace_function(*args)

      expect(recorder.commands).to eq [[:replace_function, args, nil]]
    end

    it "reverts to replace_function with the specified revert_to_version" do
      args = [:users, { version: 2, revert_to_version: 1 }]
      revert_args = [:users, { version: 1 }]

      recorder.revert { recorder.replace_function(*args) }

      expect(recorder.commands).to eq [[:replace_function, revert_args]]
    end

    it "raises when reverting without revert_to_version set" do
      args = [:users, { version: 42, another_argument: 1 }]

      expect { recorder.revert { recorder.replace_function(*args) } }
        .to raise_error(ActiveRecord::IrreversibleMigration)
    end
  end

  describe "#create_aggregate" do
    it "records the created aggregate" do
      recorder.create_aggregate :greetings

      expect(recorder.commands).to eq [[:create_aggregate, [:greetings], nil]]
    end

    it "reverts to drop_aggregate" do
      recorder.revert { recorder.create_aggregate :greetings }

      expect(recorder.commands).to eq [[:drop_aggregate, [:greetings]]]
    end
  end

  describe "#drop_aggregate" do
    it "records the dropped aggregate" do
      recorder.drop_aggregate :users

      expect(recorder.commands).to eq [[:drop_aggregate, [:users], nil]]
    end

    it "reverts to create_aggregate with specified revert_to_version" do
      args = [:users, { revert_to_version: 3 }]
      revert_args = [:users, { version: 3 }]

      recorder.revert { recorder.drop_aggregate(*args) }

      expect(recorder.commands).to eq [[:create_aggregate, revert_args]]
    end

    it "raises when reverting without revert_to_version set" do
      args = [:users, { another_argument: 1 }]

      expect { recorder.revert { recorder.drop_aggregate(*args) } }
        .to raise_error(ActiveRecord::IrreversibleMigration)
    end
  end

  describe "#update_aggregate" do
    it "records the updated aggregate" do
      args = [:users, { version: 2 }]

      recorder.update_aggregate(*args)

      expect(recorder.commands).to eq [[:update_aggregate, args, nil]]
    end

    it "reverts to update_aggregate with the specified revert_to_version" do
      args = [:users, { version: 2, revert_to_version: 1 }]
      revert_args = [:users, { version: 1 }]

      recorder.revert { recorder.update_aggregate(*args) }

      expect(recorder.commands).to eq [[:update_aggregate, revert_args]]
    end

    it "raises when reverting without revert_to_version set" do
      args = [:users, { version: 42, another_argument: 1 }]

      expect { recorder.revert { recorder.update_aggregate(*args) } }
        .to raise_error(ActiveRecord::IrreversibleMigration)
    end
  end

  def recorder
    @recorder ||= ActiveRecord::Migration::CommandRecorder.new
  end
end
