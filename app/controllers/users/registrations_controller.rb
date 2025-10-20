# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  # Override create to ensure confirmable flow flashes the appropriate message
  def create
    build_resource(sign_up_params)

    resource.save
    yield resource if block_given?
    if resource.persisted?
      if resource.active_for_authentication?
        set_flash_message! :notice, :signed_up
        sign_up(resource_name, resource)
        respond_with resource, location: after_sign_up_path_for(resource)
      else
        # This is the branch for confirmable: user signed up but not confirmed
        set_flash_message! :notice, :signed_up_but_unconfirmed
        expire_data_after_sign_in!
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end
end
