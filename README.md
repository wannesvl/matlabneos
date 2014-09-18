matlabneos
==========

A MATLAB interface to neos

Installation
------------
Add `.jar` file to `javaclasspath`

    javaclasspath('/path/to/xmlrpc-client-1.1.1.jar')

Basis usage
-----------
To create an interface to neos

    neos = NeosInterface();

A given `.mod` file is converted to an xml string with

    neos.xml_string_ampl('category', 'solver', '/path/to/file');

For example

    xml_string = neos.xml_string_ampl('nco', 'ipopt', 'model.mod');

Additionally, you can add a data and commands file

A list of categories and solvers is returned by

    neos.get_categories()
    neos.get_solvers('AMPL')  % or 'GAMS', ...

Once we have an xml string for the solver and model files, we can call the solver

    sol = neos.submit_job(xml_string);

which returns a structure containing the solver output and the solution vector in the fields `report` and `x`.