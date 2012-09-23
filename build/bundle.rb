def description(name)
    name = name.split(/\W/).map { |c| c.capitalize }.join(' ')

    "Build Kendo UI #{name}"
end

def bundle(options)
    name = options[:name]
    eula = options[:eula]
    readme = options[:readme]
    vsdoc_sources = options[:vsdoc]
    changelog_suites = options[:changelog]
    demo_suites = options[:demos]
    path = "dist/bundles/#{name}"
    license = nil

    prerequisites = [:js, :less] + options[:prerequisites].to_a

    if options[:license]
        license = "#{path}.license"
        file_license license => File.join(LEGAL_DIR, "#{options[:license]}.txt")
    end

    options[:contents].each do |target, contents|

        root = ROOT_MAP[target]

        raise "Nothing specified for '#{target}' in ROOT_MAP" unless root

        to = "#{path}/#{target}"

        tree :to => to,
             :from => contents,
             :root => ROOT_MAP[target],
             :license => license

        prerequisites.push(to)
    end

    if eula
        license_agreements_path = File.join(path, "license-agreements")
        third_party_path = File.join(license_agreements_path, "third-party")
        source_path = File.join(LEGAL_DIR, eula + "-eula")

        tree :to => license_agreements_path,
             :from =>  File.join(source_path, "*"),
             :root => source_path

        tree :to => third_party_path,
             :from =>  File.join(THIRD_PARTY_LEGAL_DIR, "*"),
             :root => THIRD_PARTY_LEGAL_DIR

        prerequisites.push(license_agreements_path)
        prerequisites.push(third_party_path)
    end

    if readme
        readme_path = File.join(path, "README")
        file_copy :to => readme_path, :from => File.join(README_DIR, "#{readme}.txt")
        prerequisites.push(readme_path)
    end

    if vsdoc_sources
        sources = FileList["docs/api/{#{vsdoc_sources.keys[0].join(",")}}/*.md"]
        vsdoc_path = File.join(path, "vsdoc", "kendo.#{vsdoc_sources.values[0]}-vsdoc.js")
        vsdoc vsdoc_path => sources
        prerequisites.push(vsdoc_path)
    end

    if changelog_suites
        prerequisites.push(:fetch_changelog)

        changelog_path = File.join(path, "changelog.html")
        write_changelog(changelog_path, changelog_suites)
        prerequisites.push(changelog_path)
    end

    if demo_suites
        demo_files = demos( {
            :path => path,
            :suites => demo_suites
        })

        prerequisites = prerequisites + demo_files
    end

    zip "#{path}.zip" =>  prerequisites

    desc description(name)
    task "bundles:#{name}" => "#{path}.zip"
end

