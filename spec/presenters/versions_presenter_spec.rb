# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VersionsPresenter do
  subject(:versions) do
    described_class.new(druid: 'druid:bc123df4567', version_inventory:, milestones: [], user_version_inventory:)
                   .versions
  end

  let(:version_inventory) do
    [1, 2, 3].map { |version| Dor::Services::Client::ObjectVersion::Version.new(versionId: version, message: "v#{version}", cocina: version > 1) }
  end
  let(:user_version_inventory) do
    [
      Dor::Services::Client::UserVersion::Version.new(version: 1, userVersion: 1, head: false, withdrawn: true,
                                                      withdrawable: false, restorable: true),
      Dor::Services::Client::UserVersion::Version.new(version: 3, userVersion: 2, head: true, withdrawn: false,
                                                      withdrawable: false, restorable: false)
    ]
  end

  it 'links the latest user version to the PURL, and does not link a withdrawn user version' do
    expect(versions.map { |version| [version.version, version.user_version, version.purl_url] }).to eq(
      [
        [3, 2, 'https://purl.stanford.edu/bc123df4567'],
        [2, nil, nil],
        [1, 1, nil]
      ]
    )
  end

  it 'indicates whether each version is withdrawn' do
    expect(versions.map(&:withdrawn?)).to eq([false, false, true])
  end

  context 'when a user version is withdrawable or permanently withdrawn' do
    let(:user_version_inventory) do
      [
        Dor::Services::Client::UserVersion::Version.new(version: 1, userVersion: 1, head: false, withdrawn: false,
                                                        withdrawable: false, restorable: false),
        Dor::Services::Client::UserVersion::Version.new(version: 2, userVersion: 2, head: false, withdrawn: false,
                                                        withdrawable: true, restorable: false),
        Dor::Services::Client::UserVersion::Version.new(version: 3, userVersion: 3, head: true, withdrawn: false,
                                                        withdrawable: false, restorable: false)
      ]
    end

    it 'treats the permanently withdrawn user version as withdrawn' do
      expect(versions.map(&:withdrawn?)).to eq([false, false, true])
    end

    it 'links an earlier public user version to its versioned PURL, but not a permanently withdrawn one' do
      expect(versions.map(&:purl_url)).to eq(
        ['https://purl.stanford.edu/bc123df4567', 'https://purl.stanford.edu/bc123df4567/version/2', nil]
      )
    end
  end

  it 'indicates whether DSA has stored cocina for each version' do
    expect(versions.map(&:cocina?)).to eq([true, true, false])
  end
end
