EXEC_PATH=./bin/zig-search
TEST_PARAMS=${HOME} password

build-exe:
	zig build-exe src/main.zig \
	--name zig-search -O ReleaseSafe \
	--build-id=sha1 -static

	mv zig-search* bin


# Search all file that cointains the "password" word
test: build-exe
	${EXEC_PATH} ${TEST_PARAMS}

dev:
	zig run src/main.zig -- ${TEST_PARAMS}