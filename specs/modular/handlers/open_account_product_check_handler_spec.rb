describe OpenAccountProductCheckHandler do
  subject(:handler) { OpenAccountProductCheckHandler.new(esb_adapter) }
  let(:request) { double('client_id': '1614116104', 'currencies': ["USD", "KZT"]) }
  let(:esb_adapter) { double }

  let(:success_response) { double(
    uid: '1111',
    ErrCode: '0',
    ErrText: '',
    entity_number: "790315300122",
    name: "Иванов Иван Иванович",
    birth_date: "2017-08-04",
    recommended_branch_code: "002",
    branches: [
      {
        code: "002",
        name: "Алматинский филиал",
        city: "Алматы",
        address: "пр. Абая 42"
      }
    ]
  )}

  let(:failure_response) { double(
    uid: '1111',
    ErrCode: '0',
    ErrText: '',
    entity_number: "790315300122",
    name: "Иванов Иван Иванович",
    birth_date: "2017-08-04",
    recommended_branch_code: "002",
    branches: []
  )}

  context 'когда возвращается хотя бы один филиал' do
    before do
      allow(esb_adapter).to receive(:openAccountProductCheck).with(request).and_return(success_response)
    end

    it 'запрашивает список филиалов из ESB' do
      result = handler.handle(request)
      expect(esb_adapter).to have_received(:openAccountProductCheck).with(request)
      expect(result.branches).not_to be_empty
    end
  end

  context 'когда возвращается пустой список филиалов' do
    before do
      allow(esb_adapter).to receive(:openAccountProductCheck).with(request).and_return(failure_response)
      allow(request).to receive(:[]).with('client_id')
      allow(request).to receive(:[]).with('currencies')
    end

    it 'должен вернуть ошибку' do
      result = handler.handle(request)
      expect(esb_adapter).to have_received(:openAccountProductCheck).with(request)
      expect(result[:message]).to match('Извините, но банк отказал Вам в открытии текущего счета. Обратитесь в отделение банка')
      expect(result[:success]).to be_falsy
    end
  end
end
