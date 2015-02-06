require 'log4r'

require 'vagrant/action/builder'

require 'vagrant-openstack-provider/action/abstract_action'
require 'vagrant-openstack-provider/action/read_ssh_info'

module VagrantPlugins
  module Openstack
    module Action
      include Vagrant::Action::Builtin

      class ProvisionWrapper < AbstractAction
        def initialize(app, env)
          @app    = app
          @env    = env
          @logger = Log4r::Logger.new('vagrant_openstack::action::provision_wrapper')
        end

        def execute(env)
          @logger.info 'Run provisioning'
          InternalProvisionWrapper.new(@app, @env).call(@env)
          @app.call(env)
        end
      end

      class InternalProvisionWrapper < Vagrant::Action::Builtin::Provision
        def initialize(app, env)
          @logger = Log4r::Logger.new('vagrant_openstack::action::internal_provision_wrapper')
          super app, env
        end

        def run_provisioner(env)
          if env[:provisioner].class == VagrantPlugins::Shell::Provisioner
            config = env[:provisioner].config
            args = [config.args].flatten
            config.args = []
            args.each do |arg|
              if arg == '@@ssh_ip@@'
                ssh_info = VagrantPlugins::Openstack::Action.get_ssh_info(env)
                config.args << ssh_info[:host]
              else
                config.args << arg
              end
            end
          end
          env[:provisioner].provision
        end
      end
    end
  end
end
