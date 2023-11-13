shared_examples 'reseting homework service context' do |destroy_answers: true|
  before do
    allow(Homeworks::ResetHomeworkService).to receive(:call).
      with(homework: user_homework).and_return(reset_service_status)
  end

  context 'when reseting homework service returns success' do
    let(:reset_service_status) { Success() }

    it 'executes successfully' do
      expect(subject).to be_success
    end

    if destroy_answers
      include_examples 'destroys learner answers'
    else
      include_examples 'does not destroy learner answers'
    end

    include_examples 'calls reseting homework service'
  end

  context 'when reseting homework service returns failure' do
    let(:reset_service_status) { Failure() }

    include_examples 'service executes with failure'
    include_examples 'calls reseting homework service'
  end
end

shared_examples 'service executes with failure' do
  it 'executes with failure' do
    expect(subject).to be_failure
  end

  include_examples 'does not destroy learner answers'
end

shared_examples 'destroys learner answers' do
  it 'destroys learner answers' do
    subject

    expect(user.question_answers).to be_empty
  end
end

shared_examples 'does not destroy learner answers' do
  it 'does not destroy learner answers' do
    expect { subject }.not_to change { Homeworks::QuestionAnswer.count }
  end
end

shared_examples 'calls reseting homework service' do
  it 'calls reseting homework service' do
    subject

    expect(Homeworks::ResetHomeworkService).to have_received(:call).
      with(homework: user_homework)
  end
end

shared_examples 'does not call reseting homework service' do
  it 'does not call reseting homework service' do
    subject

    expect(Homeworks::ResetHomeworkService).not_to receive(:call)
  end
end

RSpec.describe Homeworks::CancelHomeworkService do
  subject { described_class.call(params) }

  let(:params) { {homework: user_homework} }
  let(:lesson) { create(:lesson, :homework) }
  let(:user_homework) { create(:user_homework, lesson: lesson) }
  let(:user) { user_homework.user }
  let(:question) { create(:question) }
  let!(:answer) { create(:question_answer, user: user, lesson: lesson, question: question) }

  it_behaves_like 'service'
  it_behaves_like 'validate params presence', %i{homework}

  context 'when learner answers are found' do
    context 'when learner answers can be destroyed' do
      include_examples 'reseting homework service context'
    end

    context 'when destroying learner answers fails' do
      before do
        allow_any_instance_of(ActiveRecord::Relation).to receive(:empty?).and_return(false)
      end

      include_examples 'service executes with failure'
      include_examples 'does not call reseting homework service'
    end
  end

  context 'when learner answers are not found' do
    let!(:answer) { nil }

    include_examples 'reseting homework service context', destroy_answers: false
  end
end
