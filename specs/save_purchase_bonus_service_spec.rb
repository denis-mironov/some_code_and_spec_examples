shared_examples 'failure execution when updating purchase bonus' do
  it 'does not create purchase bonus items' do
    expect { subject }.not_to change { PurchaseBonusItem.count }
  end

  it 'does not destroy previous purchase bonus items' do
    subject

    purchase_item_ids = purchase_bonus.purchase_bonus_items.pluck(:purchase_item_id)
    expect(purchase_item_ids).to match([master_course.id])
  end

  include_examples 'executes with failure'
end

shared_examples 'failure execution when creating purchase bonus' do |klass|
  before do
    allow_any_instance_of(ActiveRecord::Associations::CollectionProxy).
      to receive(:build).with(any_args).and_return(klass.new)
  end

  it 'does not create purchase bonus required items' do
    expect { subject }.not_to change { PurchaseBonusRequiredItem.count }
  end

  it 'does not create purchase bonus items' do
    expect { subject }.not_to change { PurchaseBonusItem.count }
  end

  it 'does not create purchase bonus' do
    expect { subject }.not_to change { PurchaseBonus.count }
  end

  include_examples 'executes with failure'
end

shared_examples 'creates purchase bonus required items' do
  it 'creates purchase bonus required items' do
    expect { subject }.to change { PurchaseBonusRequiredItem.count }.by(1)
  end
end

shared_examples 'creates new purchase bonus items' do |count|
  it 'creates new purchase bonus items' do
    expect { subject }.to change { PurchaseBonusItem.count }.by(count)
  end
end

shared_examples 'creates purchase bonus' do
  it 'creates purchase bonus' do
    expect { subject }.to change { PurchaseBonus.count }.by(1)
  end
end

shared_examples 'executes successfully' do
  it 'executes successfully' do
    expect(subject).to be_success
  end
end

shared_examples 'executes with failure' do
  it 'executes with failure' do
    expect(subject).to be_failure
  end
end

RSpec.describe PurchaseBonuses::SavePurchaseBonusService do
  subject { described_class.call(params) }

  let(:required_master_course) { create(:master_course) }
  let(:bonus_master_courses) { create_list(:master_course, 2) }
  let(:params) {
    {
      required_master_course: required_master_course,
      bonus_master_courses:   bonus_master_courses,
    }
  }

  it_behaves_like 'service'
  it_behaves_like 'validate params presence', %i{required_master_course bonus_master_courses}

  context 'when updating current purchase bonus' do
    let(:master_course) { create(:master_course) }
    let!(:purchase_bonus) {
      create(:purchase_bonus,
             purchase_bonus_items: purchase_bonus_items,
             purchase_bonus_required_items: purchase_bonus_required_items)
    }
    let(:purchase_bonus_items) {
      build_list(:purchase_bonus_item, 1, purchase_item: master_course)
    }
    let(:purchase_bonus_required_items) {
      build_list(:purchase_bonus_required_item, 1, purchase_item: required_master_course)
    }

    context 'when current purchase bonus items destroyed' do
      context 'when new purchase bonus items builded' do
        context 'when new purchase bonus items saved' do
          it 'destroys current purchase bonus items' do
            subject

            purchase_bonus.purchase_bonus_items.reload
            new_purchase_item_ids = purchase_bonus.purchase_bonus_items.pluck(:purchase_item_id)
            expect(new_purchase_item_ids).to match(bonus_master_courses.map(&:id))
          end

          include_examples 'creates new purchase bonus items', 1
          include_examples 'executes successfully'
        end

        context 'when new purchase bonus items are not saved' do
          before do
            allow_any_instance_of(PurchaseBonusItem).to receive(:save).and_return(false)
          end

          include_examples 'failure execution when updating purchase bonus'
        end
      end

      context 'when new purchase bonus items builded with error' do
        before do
          allow_any_instance_of(ActiveRecord::Associations::CollectionProxy).
            to receive(:build).with(any_args).and_return(PurchaseBonusItem.new)
        end

        include_examples 'failure execution when updating purchase bonus'
      end
    end

    context 'when current purchase bonus items destroys with errors' do
      before do
        allow_any_instance_of(ActiveRecord::Associations::CollectionProxy).
          to receive(:destroy_all).and_return([])
      end

      include_examples 'failure execution when updating purchase bonus'
    end
  end

  context 'when creating new purchase bonus' do
    context 'when purchase bonus required item builded' do
      context 'when purchase bonus items builded' do
        include_examples 'creates purchase bonus required items'
        include_examples 'creates new purchase bonus items', 2
        include_examples 'creates purchase bonus'
        include_examples 'executes successfully'
      end

      context 'when purchase bonus items builded with error' do
        include_examples 'failure execution when creating purchase bonus', PurchaseBonusItem
      end
    end

    context 'when purchase bonus required item builded with errors' do
      include_examples 'failure execution when creating purchase bonus', PurchaseBonusRequiredItem
    end
  end

  context 'when purchase bonus creates with exeptions' do
    include_examples 'failure execution when creating purchase bonus', PurchaseBonusItem
  end
end
