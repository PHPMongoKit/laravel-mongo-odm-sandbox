<?php

use Psr\Container\ContainerInterface;
/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| contains the "web" middleware group. Now create something great!
|
*/

Route::get('/', function (ContainerInterface $container) {
    /** @var \Sokil\Mongo\ClientPool $clientPool */
    $clientPool = $container->get(\Sokil\Mongo\ClientPool::class);
    $client = $clientPool->get('connect1');

    var_dump($client);
});
