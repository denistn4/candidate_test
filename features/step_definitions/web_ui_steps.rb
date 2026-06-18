# frozen_string_literal: true

When(/^захожу на страницу "(.+?)"$/) do |url|
  visit url
  $logger.info("Страница #{url} открыта")
  expect(page).to have_xpath("//body"), "Ошибка при загрузке страницы"
end

When(/^ввожу в поисковой строке текст "([^"]*)"$/) do |text|
  query = find("//input[@name='q']")
  query.set(text)
  query.native.send_keys(:enter)
  $logger.info('Поисковый запрос отправлен')
  sleep 1
end

When(/^кликаю по строке выдачи с адресом (.+?)$/) do |url|
  link_first = find("//a[@href='#{url}/']/h3")
  link_first.click
  $logger.info("Переход на страницу #{url} осуществлен")
  sleep 1
end

When(/^я должен увидеть текст на странице "([^"]*)"$/) do |text_page|
  sleep 1
  expect(page).to have_text text_page
end


When(/^выбираю в меню "(.+?)"$/) do |button_name|
  link = find(:xpath, "//header//div[not(@id='mobile-menu')]//a[contains(text(),'#{button_name}')]")
  link.click
  $logger.info("Вкладка меню выбрана")
  expect(page).to have_text(button_name), "Кнопка меню #{button_name} не найдена"
  expect(page).to have_xpath("//header//div[not(@id='mobile-menu')]//a[contains(text(),'#{button_name}')]"), "Кнопка меню #{button_name} в составе сайта не найдена"
end

When(/^перехожу во вкладку меню "(.+?)"$/)  do |link_name|
  link = find(:xpath, "//div[contains(@class, 'md:block')]//nav//a[span[contains(text(),'#{link_name}')]]")
  link.click
  $logger.info("Вкладка бокового меню выбрана")
  expect(page).to have_text(link_name), "Кнопка #{link_name} бокового меню не найдена"
  expect(page).to have_xpath("//div[contains(@class, 'md:block')]//nav//a[span[contains(text(),'#{link_name}')]]"), "Кнопка #{link_name} бокового меню не найдена в составе сайта"
end

When(/^скачиваю оттуда последний стабильный релиз$/) do
  @download_dir = File.join(Dir.pwd, 'features', 'tmp')
  section = find(:xpath, "//div//li[strong[contains(text(), 'Стабильные релизы')]]")
  releases_list = section.find(:xpath, ".//ul")
  download_link = releases_list.all('a').find { |a| a[:href]&.end_with?('.tar.gz') }
  unless download_link
    raise "Не удалось найти ссылку для скачивания"
  end
    @download_url = download_link[:href]
    @filename = File.basename(URI.parse(@download_url).path)
    @expected_path = File.join(@download_dir, @filename)
    download_link.click
    $logger.info("Ссылка #{@download_url} нажата")
    step %(ждем окончания скачивания)
    step %(проверяю, что файл находится в нужной директории)
    step %(проверяю, что это имя скаченного файла совпадает с именем файла установщика, указанного на сайте)
    step %(удаляю скаченый файл)
end

When(/^проверяю, что файл находится в нужной директории$/) do
    $logger.info("рабочая директория: #{Dir.pwd}")
    $logger.info("путь к файлу #{@expected_path}")
    $logger.info("Имя файла #{@filename}")
  if File.exist?(@expected_path)
    $logger.info("Файл в ожидаемой директории #{@expected_path}")
  else
    raise "Файл отсутствует в ожидаемой директории #{@expected_path}"
  end
end

When(/^проверяю, что это имя скаченного файла совпадает с именем файла установщика, указанного на сайте$/) do
  install_link = File.basename(URI.parse(@download_url).path)
  if @filename.sub(/\.tar\.gz$/,'') == install_link.sub(/\.tar\.gz$/,'')
    $logger.info("Скаченый файл совпадает с указаным на сайте #{install_link.sub(/\.tar\.gz$/,'')} = #{@filename.sub(/\.tar\.gz$/,'')}")
  else
    raise "Название файлов не совпадает #{install_link} != #{@filename}"
  end
end

When(/^удаляю скаченый файл$/) do
  file_path = File.join(@download_dir, @filename)
  if File.exist?(file_path)
    File.delete(file_path)
    $logger.info("Уничтожен: #{file_path}")
  else
    $logger.info("Не удалось удалить файл: #{file_path}")
  end
end


When (/^ждем окончания скачивания$/) do
  total_timeout = 300
  timeout = 1
  start_time = Time.now
  download_dir = @download_dir
  filename = @filename
  temp_extension = '.part'

  loop do
    elapsed_time = Time.now - start_time
    break if elapsed_time > total_timeout
    temp_files = Dir.glob(File.join(download_dir, "#{filename}.#{temp_extension}"))
    final_files = Dir.glob(File.join(download_dir, filename)).select { |f| File.size(f) > 0 }
    if final_files.any? && temp_files.empty?
      $logger.info("Скачивание успешно #{final_files.first}")
      break
    end
    if timeout + 1 <= total_timeout
      timeout += 1
    else
      timeout = total_timeout
    end
  end
  unless Dir.glob(File.join(download_dir, filename)).any? { |f| File.size(f) > 0 }
    raise "Скачивание файла не завершилось"
  end
end