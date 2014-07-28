Pod::Spec.new do |s|
    s.name        = 'SystemMonitor'
    s.version     = '1.0'
    s.license     = 'Apple Public Source License 2.0'

    s.summary     = 'View and blacklist or whitelist active connections and current processes on device.'
    s.description = %[
        View active connections and current processes on device. Note: this library makes use of system calls; Apple will not accept any app built using it.
    ]
    s.homepage    = 'https://github.com/project-imas/system-monitor'
    s.authors     = {
        'MITRE' => 'imas-proj-list@lists.mitre.org'
    }

    s.source      = {
        :git => 'https://github.com/project-imas/system-monitor.git',
        :tag => s.version.to_s
    }
    s.source_files = 'SystemMonitor/**/*.{h,m}'
    s.exclude_files = 'SystemMonitor-Prefix.pch'

    s.platform = :ios
    s.requires_arc = true
end
