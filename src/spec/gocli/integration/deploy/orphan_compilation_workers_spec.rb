require 'spec_helper'
require 'fileutils'

describe 'compilation.orphan_workers', type: :integration do
  with_reset_sandbox_before_each

  let(:manifest) do
    manifest = Bosh::Spec::NewDeployments.simple_manifest_with_instance_groups(instances: 1, azs: ['z1'])
    manifest
  end

  let(:cloud_config) do
    cloud_config = Bosh::Spec::NewDeployments.simple_cloud_config_with_multiple_azs
    cloud_config['compilation'] = cloud_config['compilation'].merge('orphan_workers' => orphan_compilation_workers)
    cloud_config
  end

  before do
    deploy_from_scratch(manifest_hash: manifest, cloud_config_hash: cloud_config)
  end

  context 'when enabled' do
    let(:orphan_compilation_workers) { true }

    it 'orphans the compilation vms without deleting them' do
      orphaned_vms = table(bosh_runner.run('orphaned-vms', json: true))
      expect(orphaned_vms.length).to eq(2)

      expect(orphaned_vms[0]['instance']).to match(/compilation-.+/)
      expect(orphaned_vms[1]['instance']).to match(/compilation-.+/)
    end
  end

  context 'when disabled' do
    let(:orphan_compilation_workers) { false }

    it 'deletes compilation vms' do
      orphaned_vms = table(bosh_runner.run('orphaned-vms', json: true))
      expect(orphaned_vms.length).to eq(0)

      expect(current_sandbox.cpi.invocations_for_method('delete_vm').count).to eq(2)
    end
  end
end
