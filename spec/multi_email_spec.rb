require 'rails_helper'

RSpec.describe 'Devise Mutil Email' do
  describe '.required_fields' do
    it 'does not raise any errors' do
      expect { Devise::Models.check_fields!(User) }.to_not raise_error
      expect { Devise::Models.check_fields!(Email) }.to_not raise_error
    end
  end

  describe 'Authenticatable' do
    context 'when emails association is not detected' do
      it 'raises an error' do
        expect do
          class UserWithoutEmail < ActiveRecord::Base
            self.table_name = 'users'

            devise :multi_email_authenticatable
          end
        end.to raise_error(RuntimeError)
      end
    end

    context 'when user association is not detected' do
      it 'raises an error' do
        expect do
          class EmailWithoutUser < ActiveRecord::Base
            self.table_name = 'emails'
          end

          class UserWithEmails < ActiveRecord::Base
            self.table_name = 'users'

            has_many :emails, class_name: EmailWithoutUser.name
            devise :multi_email_authenticatable
          end

          EmailWithoutUser.new.devise_scope
        end.to raise_error(RuntimeError)
      end
    end

    describe '#email=' do
      let(:user) { create_user }

      it 'creates a new Email' do
        expect(user.emails.length).to eq(1)
        expect(user.emails[0]).to be_primary
      end

      it 'deletes the only email address when assigning nil' do
        user.email = nil
        expect(user.email).to eq(nil)
      end
    end
  end

  describe 'Validatable' do
    context 'when email is a nested attribute' do
      class UserWithNestedAttributes < ActiveRecord::Base
        self.table_name = 'users'
        has_many :emails, foreign_key: :user_id

        devise :multi_email_authenticatable, :multi_email_validatable

        accepts_nested_attributes_for :emails
      end

      it 'propagates the errors to user' do
        user = UserWithNestedAttributes.new(username: 'user', email: 'inavlid_email@')
        expect(user).not_to be_valid
        expect(user.errors[:email]).to be_present
      end
    end
  end
end
