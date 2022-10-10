untyped
globalize_all_functions

void function MessageLoop_Init()
{
    thread MessageLoop_Thread()
}

void function MessageLoop_Thread()
{
    while ( true )
    {
        WaitFrame()
        NSProcessMessages()
    }
}

void function testabc(string input) {
    print(input)
}

void function testtable(table input) {
    PrintTable(input)
}

void function testarray(array<string> input) {
    foreach (x in input) {print(x)}
}