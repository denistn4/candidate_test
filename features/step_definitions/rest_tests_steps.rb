# frozen_string_literal: true

When(/^получаю информацию о пользователях$/) do
  users_full_information = $rest_wrap.get('/users')

  $logger.info('Информация о пользователях получена')
  @scenario_data.users_full_info = users_full_information
end

When(/^проверяю (наличие|отсутствие) логина (\w+\.\w+) в списке пользователей$/) do |presence, login|
  search_login_in_list = true
  search_login_in_list = presence == 'отсутствие' ? false : true

  logins_from_site = @scenario_data.users_full_info.map { |f| f.try(:[], 'login') }
  login_presents = logins_from_site.include?(login)

  if login_presents
    message = "Логин #{login} присутствует в списке пользователей"
    search_login_in_list ? $logger.info(message) : raise(message)
  else
    message = "Логин #{login} отсутствует в списке пользователей"
    search_login_in_list ? raise(message) : $logger.info(message)
  end
end

When(/^добавляю пользователя c логином (\w+\.\w+) именем (\w+) фамилией (\w+) паролем ([\d\w@!#]+)$/) do
|login, name, surname, password|

  response = $rest_wrap.post('/users', login: login,
                                       name: name,
                                       surname: surname,
                                       password: password,
                                       active: 1)
  $logger.info(response.inspect)
end

When(/^добавляю пользователя с параметрами:$/) do |data_table|
  user_data = data_table.raw

  login = user_data[0][1]
  name = user_data[1][1]
  surname = user_data[2][1]
  password = user_data[3][1]

  step "добавляю пользователя c логином #{login} именем #{name} фамилией #{surname} паролем #{password}"
end

When(/^нахожу пользователя с логином (\w+\.\w+)$/) do |login|
  step %(получаю информацию о пользователях)
  if @scenario_data.users_id[login].nil?
    @scenario_data.users_id[login] = find_user_id(users_information: @scenario_data
                                                                         .users_full_info,
                                                  user_login: login)
  end

  $logger.info("Найден пользователь #{login} с id:#{@scenario_data.users_id[login]}")
end


When (/^удаляю пользователя (\w+\.\w+) по логину$/) do |login|
  step %(нахожу пользователя с логином #{login})
  user_id = @scenario_data.users_id[login]
  if user_id.nil?
    $logger.error("Не найден пользователь с логином #{login}")
    next
  end
  response = $rest_wrap.delete("/users/#{user_id}")
  $logger.info("Удален пользователь #{login} с id #{user_id} #{response}")
  end

When(/^изменяю доступные параметры пользователя (\w+\.\w+) по логину на:$/) do |login, data_table|
  user_data = data_table.raw.to_h
  step %(нахожу пользователя с логином #{login})
  user_id = @scenario_data.users_id[login]
  if user_id.nil?
    $logger.error("Не найден пользователь с логином #{login}")
    next
  end
  response = $rest_wrap.put("/users/#{user_id}", user_data)
  $logger.info("Данные пользователя #{login} обновлены #{response}")
end

When(/^смотрю новые данные пользователя с логином (\w+\.\w+)$/) do |login|
  step %(нахожу пользователя с логином #{login})
  user_id = @scenario_data.users_id[login]
  if user_id.nil?
    $logger.error("Пользователь с логином #{login} не найден")
    next
  end
  response = $rest_wrap.get("/users/#{user_id}")
  $logger.info("Новые данные пользователя #{login}: #{response}")
end

When(/добавляю уже существующего пользователя с логином (\w+\.\w+) именем (\w+) фамилией (\w+) паролем ([\d\w@!#]+)$/) do |login, name, surname, password|
  response = $rest_wrap.post('/users', login: login,
                             name: name,
                             surname: surname,
                             password: password,
                             active: 1)
  expect(response.inspect).to be_nil
rescue
  $logger.info ("Пользователь с логином #{login} уже существует")
end

When(/добавляю пользователя с некорректными данными$/) do |data_table|
  user_data = data_table.rows_hash
  response = $rest_wrap.post('/users', login: user_data['login'] || '',
                             name: user_data['name'] || '',
                             surname: user_data[ 'surname'] || '',
                             password: user_data[password] || '',
                             active: 1)
  expect(response.inspect).to be_nil
rescue
  $logger.info("Пользователь с неверными данными не добавлен #{response} Введенные данные: #{user_data}")
end

When(/изменяю параметры пользователя (\w+\.\w+) по логину на некорректные:$/) do |login, data_table|
  user_data = data_table.raw.to_h
  step %(нахожу пользователя с логином #{login})
  user_id = @scenario_data.users_id[login]
  if user_id.nil?
    $logger.error("Не найден пользователь с логином #{login}")
    next
  end
  response = $rest_wrap.put("/users/#{user_id}", user_data)
    raise "Данные пользователя #{login} успешно обновлены Ответ сервера 200"
rescue
  $logger.info("Не удалось обновить данные пользователя #{login} Ошибка сервера #{response}")
end

When(/добавляю пользователя с длинной полей от 100 до 500 символов$/) do
  length_login = rand(100..500)
  length_name = rand(100..500)
  length_surname = rand(100..500)
  length_password = rand(100..500)
  login = 'x' * length_login
  name = 'x' * length_name
  surname = 'x' * length_surname
  password = 'x' * length_password
  response = $rest_wrap.post('/users', login: login,
                             name: name,
                             surname: surname,
                             password: password,
                             active: 1)
  expect(response.inspect).to be_nil
rescue
  $logger.info("Превышена допустимая длинна полей для логина #{login.length} имени #{name.length} фамилии #{surname.length} пароля #{password.length}")
end