EXEC_PATH=./bin/zig-search
TEST_PARAMS=${HOME} "password" -f txt,dart,js -t 16 -e ${CURDIR}/results/zig-result.txt

build-exe:
	zig build-exe src/main.zig \
	--name zig-search \
	--build-id=sha1 -static

	mv zig-search* bin

# Search all file that cointains the "password" word
test: build-exe
	${EXEC_PATH} ${TEST_PARAMS}

rundev:
	zig run src/main.zig -- ${TEST_PARAMS}

runrelease:
	./bin/zig-search ${TEST_PARAMS}
