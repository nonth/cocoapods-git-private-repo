require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Command::Repo do
    describe 'CLAide' do
      it 'registers it self' do
        Command.parse(%w{ repo }).should.be.instance_of Command::Repo
      end
    end
  end
end

