describe SeoSettingPolicy do
  let(:object) { create(:seo_setting) }
  let(:user) { create(:user) }

  it_behaves_like 'Check policies', roles: :admin,
                  actions: %i{
                    manage_seo_settings?
                    index?
                    show?
                    create?
                    update?
                    destroy?
                  }

  context 'when user has role seo_editor' do
    before do
      user.add_role(:seo_editor)
    end

    permissions :manage_seo_settings?, :index?, :show?, :create?, :update?, :destroy? do
      it 'should grant access' do
        expect(described_class).to permit(user, object)
      end
    end
  end
end
