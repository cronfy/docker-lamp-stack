<?php

/*
* https://stackoverflow.com/c/itweb/questions/34
* 

Скрипт сделает следующее:

 * Пропишет имя домена в настройках Главного модуля.
 * Пропишет имя домена в настройках сайта s1.
 * Отключит ограничение по имени хоста в Проактивной защите.
 * Использование: разместить скрипт на локальном сайте, поправить $config['domain'], запустить.

*/

// определяем namespace, чтобы не было конфликта с глобальными переменными и ф-ями
namespace dev;

// Редактировать только здесь - название домена
$config = [
    'domain' => 'mysite.ru'
];






function requireProlog() {

    //
    // перед подключением пролога отключаем все обработчики событий, которые могут нам помешать
    //

    require_once($_SERVER['DOCUMENT_ROOT'].'/bitrix/modules/main/lib/eventmanager.php');
    $eventManager = \Bitrix\Main\EventManager::getInstance();

    // на OnPageStart может быть повешен какой-нибудь модуль редиректов, который перенаправит
    // нас на другое имя сайта еще до того, как мы начнем менять настройки модулей
    // отключаем все обработчики
    $eventManager->addEventHandler("main", "OnPageStart", function () use ($eventManager) {
        $handlers = $eventManager->findEventHandlers('main', 'OnBeforeProlog');
        foreach ($handlers as $key => $event) {
             $eventManager->removeEventHandler('main', 'OnBeforeProlog', $key);
        }
    });

    //
    // теперь можно подключить пролог.
    //

    // инклудим внутри ф-ии, чтобы не было влияния переменных, которые определяет пролог,
    // на наш код (например, он может переопределить $config)
    require_once($_SERVER['DOCUMENT_ROOT'].'/bitrix/modules/main/include/prolog_before.php');
}

function disableHostRestriction() {
    // отключаем ограничение по хостам
    // check http://SITE_NAME/bitrix/admin/security_hosts.php?lang=ru&find_rule_type=M
    $hosts = new \Bitrix\Security\HostRestriction();
//    $properties = $hosts->getProperties();
//    print_r($properties);die();
    $hosts->setActive(false)->save();
}

function setMainDomain($domain) {
    // устанавливаем домен в главном модуле
    // check http://SITE_NAME/bitrix/admin/settings.php?lang=ru&mid=main&mid_menu=1
    \Bitrix\Main\Config\Option::set('main', 'server_name', $domain);
}

function setS1Domain($domain) {
//    $siteRes = \CSite::GetByID('s1');
//    $site = $siteRes->GetNext();
//    print_r($site);
//    die();

    // устанавливаем домен в настройках сайта
    // check http://SITE_NAME/bitrix/admin/site_edit.php?lang=ru&LID=s1
    $CSite = new \CSite();
    $res = $CSite->Update('s1', [
        'SERVER_NAME' => $domain,
        'DOMAINS' => $domain
    ]);

    echo $CSite->LAST_ERROR;
}





requireProlog();
disableHostRestriction();
setMainDomain($config['domain']);
setS1Domain($config['domain']);

echo "All done";
