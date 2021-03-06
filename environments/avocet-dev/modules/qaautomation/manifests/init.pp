class qaautomation ($log_file_path = '/var/log/nightly.log') {

    #
    # This class sets up the necessary files and scripts to
    # automatically redeploy a QA server each night.
    #
    # The only manual intervention that is required to get clean
    # nightly QA servers is to generate a set of data after the initial
    # puppet run.
    # The nightly script will load in the same data each night,
    # this is to keep a consistent set of username/passwords and allow for
    # QA verification of identified and possibly fixed problems.
    #
    # The nightly script performs:
    #  * redeploy latest backend and front end code
    #  * minify and concatenate all the UI code.
    #  * stop all the services
    #  * remove all data in cassandra, elasticsearch, rabbitmq
    #  * start all the services back up
    #  * load in a pre-generated set of data via the model loader.
    #

    $backup_dir = hiera('automation_backup_dir')
    $scripts_dir = hiera('automation_scripts_dir')
    $cassandra_data_dir = hiera('db_data_dir')
    $elasticsearch_data_dir = hiera('search_data_dir')
    $user_files_dir = hiera('app_files_dir')
    $app_root_dir = hiera('app_root_dir')
    $ux_root_dir = hiera('ux_root_dir')

    $web_domain = hiera('web_domain')
    $app_admin_tenant = hiera('app_admin_tenant', 'admin')
    $admin_host = "${app_admin_tenant}.${web_domain}"


    $flickr_api_key = hiera('automation_flickr_api_key')
    $flickr_api_secret = hiera('automation_flickr_api_secret')
    $slideshare_shared_secret = hiera('automation_slideshare_shared_secret')
    $slideshare_api_key = hiera('automation_slideshare_api_key')

    $addendum_url = hiera('automation_addendum_url')

    exec { 'mkdir_scripts': command => "mkdir -p ${scripts_dir}", unless => "test -d ${scripts_dir}" }

    file { 'deletedata.sh':
        path => "${scripts_dir}/deletedata.sh",
        mode => 0755,
        content => template('qaautomation/deletedata.sh.erb')
    }

    file { 'journals.csv':
        path => "${scripts_dir}/journals.csv",
        content => template('qaautomation/journals.csv'),
    }

    file { 'departments.csv':
        path => "${scripts_dir}/departments.csv",
        content => template('qaautomation/departments.csv'),
    }

    file { 'nightly.sh':
        path => "${scripts_dir}/nightly.sh",
        mode => 0755,
        content => template('qaautomation/nightly.sh.erb'),
        require => Exec['mkdir_scripts']
    }

    file { 'shutdown.sh':
        path => "${scripts_dir}/shutdown.sh",
        mode => 0755,
        content => template('qaautomation/shutdown.sh.erb'),
        require => Exec['mkdir_scripts']
    }

    cron { 'nightly-backup':
        ensure  => present,
        command => "${scripts_dir}/nightly.sh >> ${log_file_path} 2>> ${log_file_path}",
        user    => 'root',
        target  => 'root',
        hour    => 4,
        minute  => 0
    }
}
