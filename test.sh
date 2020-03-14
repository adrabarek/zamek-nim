mkdir test_zamek
pushd test_zamek
../zamek_cli --verbose create
../zamek_cli --verbose add "My Note 0", "tag0, tag1, tag2", "my_note1", "Contents of My Note 0."
popd
rm -rf test_zamek