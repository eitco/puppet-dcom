Facter.add(:temp_path) do
    setcode do
        ENV['TEMP']
    end
end