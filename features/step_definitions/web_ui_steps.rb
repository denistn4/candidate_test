# frozen_string_literal: true

When(/^захожу на страницу "(.+?)"$/) do |url|
  visit url
  $logger.info("Страница #{url} открыта")
  sleep 3
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
  sleep 1
end

When(/^перехожу во вкладку меню "(.+?)"$/)  do |link_name|
  link = find(:xpath, "//div[contains(@class, 'md:block')]//nav//a[span[contains(text(),'#{link_name}')]]")
  link.click
  $logger.info("Вкладка бокового меню выбрана")
  sleep 3
end

When(/^скачиваю оттуда последний стабильный релиз$/) do
  section = find(:xpath, "//div//li[strong[contains(text(), 'Стабильные релизы')]]")
  releases_list = section.find(:xpath, ".//ul")
  download_link = releases_list.all('a').find { |a| a[:href]&.end_with?('.tar.gz') }
  if download_link
    download_url = download_link[:href]
    filename = File.basename(URI.parse(download_url).path)
    @download_url = download_url
    @filename=filename
    @expected_path = File.join(Dir.pwd, @filename)
    uri = URI.parse(download_url)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      request = Net::HTTP::Get.new(uri)
      http.request(request) do |response|
        open(filename, 'wb') do |file|
          response.read_body do |chunk|
            file.write(chunk)
          end
        end
      end
    end
    puts "Скачен файл: #{filename} по ссылке: #{download_url}"
  else
    puts "Ошибка скачивания"
  end
end

When(/^проверяю, что файл находится в нужной директории$/) do
    puts "рабочая директория: #{Dir.pwd}"
    puts "путь к файлу #{@expected_path}"
    puts "Имя файла #{@filename}"
  if File.exist?(@expected_path)
    puts "Файл где надо"
  else
    puts "Файл не там где надо"
  end
end

When(/^проверяю, что это имя скаченного файла совпадает с именем файла установщика, указанного на сайте$/) do
  install_link = File.basename(URI.parse(@download_url).path)
  if @filename.sub(/\.tar\.gz$/,'') == install_link.sub(/\.tar\.gz$/,'')
    puts "Одинаково #{install_link.sub(/\.tar\.gz$/,'')} = #{@filename.sub(/\.tar\.gz$/,'')}"
  else
    puts "Не одинаково #{install_link} != #{@filename}"
  end
end

When(/^удаляю скаченый файл$/) do
  file_path = File.join(Dir.pwd, @filename)
  if File.exist?(file_path)
    File.delete(file_path)
    puts "Уничтожен: #{file_path}"
  else
    puts "Мимо: #{file_path}"
  end
end