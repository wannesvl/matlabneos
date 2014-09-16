classdef NeosInterface
    properties
        client
    end
    methods
        function neos = NeosInterface(host, port)
            import redstone.xmlrpc.XmlRpcClient

            % Parse constructor arguments
            if nargin == 0
                host = 'http://neos-1.neos-server.org';
                port = '3332';
            elseif nargin == 1
                port = '3332';
            end

            client = XmlRpcClient(strcat(host, ':', port), 0);
            status = client.invoke('ping', {});
            if ~strcmp(status, 'NeosServer is alive')
                error('Unable to connect to NEOS server. Check host and port. Are you connected to the internet?');
            end
            neos.client = client;
        end

        function queue = get_queue(this)
            queue = this.client.invoke('printQueue', {});
        end

        function cat = get_categories(this)
            cat = this.client.invoke('listCategories', {});
        end

        function solvers = get_solvers(this, input_method)
            % Get solvers. If input_method is defined return solvers that
            % accept AMPL, GAMS, ... input.
            solvers = char(this.client.invoke('listAllSolvers', {}));
            solvers = strsplit(solvers(2:end-1), ', ');
            if nargin == 2
                solvers_ = [];
                for i=1:length(solvers)
                    s = char(solvers(i));
                    if strcmp(s(end-length(input_method)+1:end), upper(input_method))
                        solvers_ = [solvers_, s, ','];
                    end
                end
                solvers = strsplit(solvers_, ',');
            end
            solvers = solvers(1:end-1);
        end

        function xml_string = xml_string_ampl(varargin)
            if length(varargin) < 4
                error('Not enough input arguments')
            end
            this = varargin{1};
            category = varargin{2};
            solver = varargin{3};
            model = varargin{4};

            template = this.client.invoke('getSolverTemplate', {category, solver, 'AMPL'});
            xml_bits = strsplit(template, '...Insert Value Here...');
            if length(xml_bits) <= 1
                error('Check category and solver arguments')
            end
            xml_string = '';
            for i=1:length(varargin(4:end))
                try
                    insert = fileread(varargin{3+i});
                catch
                    insert = varargin{3+i};
                end
                xml_string = strcat(xml_string, xml_bits(i), insert);
            end
            xml_string = strcat(xml_string, xml_bits{i+1:end});
            xml_string = xmlwrite(xmlreadstring(xml_string{1}));
        end

        function result = submit_job(this, xml_string)
            response = this.client.invoke('submitJob', {xml_string});
            job = response.get(0); password = response.get(1);
            status = '';
            while ~strcmp(status, 'Done')
                status = char(this.client.invoke('getJobStatus', {job, password}));
            end
            % getFinalResults does not seem to work as desired. Something with
            % java, bytes and base64 encodings...
            % result = this.client.invoke('getFinalResults', {job, password});

            % Instead we query the webpage for the results
            url = sprintf('http://www.neos-server.org/neos/jobs/%d/%d.html', job - mod(job, 10000), job);
            result_page = urlread(url);
            report = regexp(result_page, '(?<=<PRE>).*(?=<\/PRE>)', 'match');
            disp(report{1})
            result.report = report{1};

            % Now we still need to extract the optimal value
            x = regexp(result_page, '(?<=x \[\*\] :=).*(?=;)', 'match');
            x = strread(x{1});
            i = x(:, 1:2:end);
            x = x(:, 2:2:end); x = x(:);
            n = max(i(:));
            x = x(1:n);
            result.x = x;
        end
    end
end