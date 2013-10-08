gem "minitest"
require "minitest/unit"
require "minitest/spec"
require "minitest/mock"
require "minitest/autorun" unless ENV["MT_RAILS_NO_AUTORUN"]

# Call rails/test_help because previous versions of minitest-rails
# duplicated this functionality while trying to control the order
# that the testing classes were loaded.
# Will be removed in 1.0
if require "rails/test_help"
  ActiveSupport::Deprecation.warn "It looks like you are using test helper generated by an older version of minitest-rails. Please upgrade your test_helper by following the instructions below. Support for this older helper will removed when minitest-rails reaches 1.0 release.\n\nhttps://github.com/blowmage/minitest-rails/wiki/Upgrading-to-0.9"
end

################################################################################
# Add and configure the spec DSL
################################################################################

require "active_support/test_case"
require "minitest/rails/constant_lookup"
class ActiveSupport::TestCase
  # Remove describe method, added in Rails 3
  class << self
    remove_method :describe
  end if self.respond_to? :describe

  # Add spec DSL
  extend MiniTest::Spec::DSL

  # Resolve constants from the test name when using the spec DSL
  include MiniTest::Rails::Testing::ConstantLookup
end

if defined?(ActiveRecord::Base)
  class ActiveSupport::TestCase
    # Use AS::TestCase for the base class when describing a model
    register_spec_type(self) do |desc|
      desc < ActiveRecord::Base if desc.is_a?(Class)
    end
  end
end

require "action_controller/test_case"
class ActionController::TestCase
  # Use AC::TestCase for the base class when describing a controller
  register_spec_type(self) do |desc|
    Class === desc && desc < ActionController::Metal
  end
  register_spec_type(/Controller( ?Test)?\z/i, self)

  # Resolve the controller from the test name when using the spec DSL
  def self.determine_default_controller_class(name)
    controller = determine_constant_from_test_name(name) do |constant|
      Class === constant && constant < ActionController::Metal
    end
    raise NameError.new("Unable to resolve controller for #{name}") if controller.nil?
    controller
  end
end

require "action_view/test_case"
class ActionView::TestCase
  # Use AV::TestCase for the base class for helpers and views
  register_spec_type(/(Helper( ?Test)?| View Test)\z/i, self)

  # Resolve the helper or view from the test name when using the spec DSL
  def self.determine_default_helper_class(name)
    determine_constant_from_test_name(name) do |constant|
      Module === constant
    end
  end
end

if defined? ActionMailer
  require "action_mailer/test_helper"
  require "action_mailer/test_case"
  class ActionMailer::TestCase
    # Use AM::TestCase for the base class when describing a mailer
    register_spec_type(self) do |desc|
      desc < ActionMailer::Base if desc.is_a?(Class)
    end
    register_spec_type(/Mailer( ?Test)?\z/i, self)

    # Resolve the mailer from the test name when using the spec DSL
    def self.determine_default_mailer(name)
      mailer = determine_constant_from_test_name(name) do |constant|
        Class === constant && constant < ::ActionMailer::Base
      end
      raise ActionMailer::NonInferrableMailerError.new(name) if mailer.nil?
      mailer
    end
  end
end

require "action_dispatch/testing/integration"
class ActionDispatch::IntegrationTest
  # Register by name, consider Acceptance to be deprecated
  register_spec_type(/(Integration|Acceptance)( ?Test)?\z/i, self)
end

################################################################################
# Assertions and Expectations
################################################################################

require "minitest/rails/assertions"
require "minitest/rails/expectations"

# :stopdoc:

################################################################################
# 1.8.7 Spec DSL Support
################################################################################

if LoadError.const_defined? :REGEXPS
  # Add relaxed regexp to allow whitespace so nested describes won't fail on 1.8.
  LoadError::REGEXPS.unshift(/^Missing \w+ (?:file\s*)?(.+\.rb)/i)
end

################################################################################
# Run load hooks so that other gems can register spec types
################################################################################

ActiveSupport.run_load_hooks(:minitest, ActiveSupport::TestCase)

################################################################################
# Deprecated, for backwards compatibility with older minitest-rails only
# Will be removed at version 1.0
################################################################################

module MiniTest
  module Rails
    def self.override_testunit!
      ActiveSupport::Deprecation.warn "MiniTest::Rails.override_testunit! is deprecated. Please remove calls to this method from your helper and tests. The method will removed when minitest-rails reaches 1.0 release.\n\nhttps://github.com/blowmage/minitest-rails/wiki/Upgrading-to-0.9"
      # noop
    end
    extend ::ActiveSupport::Autoload
    autoload :ActiveSupport,    'minitest/rails/deprecated/active_support'
    autoload :ActionController, 'minitest/rails/deprecated/action_controller'
    autoload :ActionView,       'minitest/rails/deprecated/action_view'
    autoload :ActionMailer,     'minitest/rails/deprecated/action_mailer'
    autoload :ActionDispatch,   'minitest/rails/deprecated/action_dispatch'
  end
end
