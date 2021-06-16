class Homeworks::CancelHomeworkService
  include ServiceCore

  option :homework

  def call
    yield validate_presence_of :homework

    answers = learner_answers(homework)
    yield cancel_homework(answers, homework)

    Success()
  end

  private

  def learner_answers(homework)
    Homeworks::QuestionAnswer.where(
      user_id: homework.user_id,
      lesson_id: homework.lesson_id
    )
  end

  def cancel_homework(answers, homework)
    ActiveRecord::Base.transaction do
      yield destroy_answers(answers) if answers.present?
      yield Homeworks::ResetHomeworkService.call(homework: homework)
    end

    Success()
  end

  def destroy_answers(answers)
    answers.destroy_all

    answers.empty? ? Success() : Failure()
  end
end
