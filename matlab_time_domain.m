function three_phase_power_gui
% Графический интерфейс пользователя для анализа трехфазной сети

    % Создание главного окна интерфейса
    hFig = figure('Name', 'Three Phase Power Analysis', 'NumberTitle', 'off', ...
                  'MenuBar', 'none', 'Toolbar', 'none', 'Position', [100, 100, 1000, 600]);

    % Создание кнопок для управления процессом
    hLoadButton = uicontrol('Style', 'pushbutton', 'String', 'Load Data', ...
                            'Position', [50, 500, 100, 30], 'Callback', @loadDataCallback);

    %% Изменение: Кнопка для перестроения графиков
    hUpdateButton = uicontrol('Style', 'pushbutton', 'String', 'Update Graphs', ...
                              'Position', [160, 500, 100, 30], 'Callback', @updateGraphs);

    % Место для отображения результатов
    hResultsText = uicontrol('Style', 'text', 'String', 'Results will be shown here', ...
                             'HorizontalAlignment', 'left', 'Position', [50, 50, 700, 400]);

    %% Изменение: Добавление чекбокса для оконной функции
    hWindowFunctionCheck = uicontrol('Style', 'checkbox', 'String', 'Apply Window Function', ...
                                     'Position', [50, 430, 150, 20], 'Value', 0); % По умолчанию выключено

    %% Изменение: Добавление чекбокса и полей ввода для фильтра
    hFilterCheck = uicontrol('Style', 'checkbox', 'String', 'Apply Bandpass Filter', ...
                             'Position', [50, 400, 150, 20], 'Value', 0);  % По умолчанию выключено

    hFilterFreqText = uicontrol('Style', 'text', 'String', 'Center Frequency (Hz):', ...
                                'Position', [220, 400, 130, 20]);
    hFilterFreqEdit = uicontrol('Style', 'edit', 'String', '50', ...
                                'Position', [350, 400, 50, 20]);

    hFilterBandText = uicontrol('Style', 'text', 'String', 'Bandwidth (Hz):', ...
                                'Position', [410, 400, 100, 20]);
    hFilterBandEdit = uicontrol('Style', 'edit', 'String', '5', ...
                                'Position', [510, 400, 50, 20]);

    hFilterOrderText = uicontrol('Style', 'text', 'String', 'Filter Order:', ...
                                 'Position', [570, 400, 80, 20]);
    hFilterOrderEdit = uicontrol('Style', 'edit', 'String', '2', ...
                                 'Position', [650, 400, 50, 20]);

    %% Добавление чекбоксов для выбора сборок
    hAssembly1Check = uicontrol('Style', 'checkbox', 'String', 'Include Assembly 1', ...
                                'Position', [50, 370, 150, 20], 'Value', 1);
    hAssembly2Check = uicontrol('Style', 'checkbox', 'String', 'Include Assembly 2', ...
                                'Position', [50, 340, 150, 20], 'Value', 1);
    hAssembly3Check = uicontrol('Style', 'checkbox', 'String', 'Include Assembly 3', ...
                                'Position', [50, 310, 150, 20], 'Value', 1);
    hAssembly4Check = uicontrol('Style', 'checkbox', 'String', 'Include Assembly 4', ...
                                    'Position', [50, 280, 150, 20], 'Value', 1);

    setappdata(hFig, 'AssemblyChecks', [hAssembly1Check, hAssembly2Check, hAssembly3Check, hAssembly4Check]);

    % Определение глобальных переменных
    global Ia_signal Va_signal Ib_signal Vb_signal Ic_signal Vc_signal Fs Fmain Nperiod Tperiod Nperiods table_values Harmonics;


    % Включение видимости фигуры после создания всех элементов интерфейса
    set(hFig, 'Visible', 'on');

    % Функция для кнопки загрузки данных
    function loadDataCallback(hObject, eventdata)
        % Запуск скрипта обработки данных
        processData();
    end

    % Функция для обновления графиков
    function updateGraphs(hObject, eventdata)
        % Получение значения Harmonics из поля ввода

        % Проверка на наличие данных перед перестроением графиков
        if isempty(Ia_signal)
            set(hResultsText, 'String', 'Please load the data first.');
            return;
        end

        % Обновление графиков с новым значением Harmonics
        analyzeAndPlot();
    end

    % Функция для обработки данных и отображения графиков
    function analyzeAndPlot
        % Получаем значения настроек из GUI
        applyWindow = get(hWindowFunctionCheck, 'Value'); % Состояние чекбокса оконной функции


        % Получаем настройки фильтра и другие параметры из GUI
        applyFilter = get(hFilterCheck, 'Value');
        centerFreq = str2double(get(hFilterFreqEdit, 'String'));
        bandwidth = str2double(get(hFilterBandEdit, 'String'));
        filterOrder = str2double(get(hFilterOrderEdit, 'String'));

        % Проверка на корректность введённых значений
        if applyFilter && (isnan(centerFreq) || isnan(bandwidth) || isnan(filterOrder) || ...
                           centerFreq <= 0 || bandwidth <= 0 || filterOrder <= 0 || mod(filterOrder, 1) ~= 0)
            set(hResultsText, 'String', 'Please enter valid filter parameters.');
            return;
        end

        % После выполнения анализа, отобразить графики
        % Проверяем, существует ли уже окно с графиками
        hGraphsFig = findobj('Tag', 'GraphsWindow');
        if isempty(hGraphsFig)
            % Создаем новое окно для графиков, если оно не существует
            hGraphsFig = figure('Tag', 'GraphsWindow', 'Name', 'Analysis Graphs', 'NumberTitle', 'off', 'Position', [110, 120, 800, 600]);
        else
            % Очищаем окно с графиками, если оно уже существует
            figure(hGraphsFig);
            clf(hGraphsFig);
        end
        % Здесь ваш код для создания графиков...
        Nperiod = Fs / Fmain; % Length of one period [counts]
        Tperiod = 1 / Fmain; % Time of one period [s]
        Nperiods = floor(length(Va_signal) / Fs / Tperiod); % Quantity of completed periods

        table_values = zeros(Nperiods, 9);
        
        for period = Nperiods-1:Nperiods-1

            %take only one period
            Va_signal_window = Va_signal(1+period*Nperiod:(period+1)*Nperiod);
            Ia_signal_window = Ia_signal(1+period*Nperiod:(period+1)*Nperiod);
            Vb_signal_window = Vb_signal(1+period*Nperiod:(period+1)*Nperiod);
            Ib_signal_window = Ib_signal(1+period*Nperiod:(period+1)*Nperiod);
            Vc_signal_window = Vc_signal(1+period*Nperiod:(period+1)*Nperiod);
            Ic_signal_window = Ic_signal(1+period*Nperiod:(period+1)*Nperiod);
        
            if applyFilter
                f_low = centerFreq - bandwidth/2;
                f_high = centerFreq + bandwidth/2;
                [b, a] = butter(2, [f_low, f_high]/(Fs/2), 'stop');
                Va_signal_window = filtfilt(b, a, Va_signal_window); % Применение фильтра
                Ia_signal_window = filtfilt(b, a, Ia_signal_window); % Применение фильтра
                Vb_signal_window = filtfilt(b, a, Vb_signal_window); % Применение фильтра
                Ib_signal_window = filtfilt(b, a, Ib_signal_window); % Применение фильтра
                Vc_signal_window = filtfilt(b, a, Vc_signal_window); % Применение фильтра
                Ic_signal_window = filtfilt(b, a, Ic_signal_window); % Применение фильтра
            end
        
            if applyWindow
                %Создание оконной функции
                window = hann(length(Va_signal_window));
                
                %Применение оконной функции к сигналу
                Va_signal_window = Va_signal_window .* window;
                Ia_signal_window = Ia_signal_window .* window;
                Vb_signal_window = Vb_signal_window .* window;
                Ib_signal_window = Ib_signal_window .* window;
                Vc_signal_window = Vc_signal_window .* window;
                Ic_signal_window = Ic_signal_window .* window;
            end
            
            Ia_RMS = sqrt(sum(Ia_signal_window.^2, 'all') / length(Ia_signal_window));
            Va_RMS = sqrt(sum(Va_signal_window.^2, 'all') / length(Va_signal_window));
            Ib_RMS = sqrt(sum(Ib_signal_window.^2, 'all') / length(Ib_signal_window));
            Vb_RMS = sqrt(sum(Vb_signal_window.^2, 'all') / length(Vb_signal_window));
            Ic_RMS = sqrt(sum(Ic_signal_window.^2, 'all') / length(Ic_signal_window));
            Vc_RMS = sqrt(sum(Vc_signal_window.^2, 'all') / length(Vc_signal_window));

            %V_RMS = sqrt(Va_RMS^2 + Vb_RMS^2 + Vc_RMS^2)
            %I_RMS = sqrt(Ia_RMS^2 + Ib_RMS^2 + Ic_RMS^2)
            V_RMS = mean([Va_RMS, Vb_RMS, Vc_RMS]) * sqrt(3)
            I_RMS = mean([Ia_RMS, Ib_RMS, Ic_RMS])
        
            Pa = sum(Va_signal_window .* Ia_signal_window, 'all') / length(Va_signal_window);
            Sa = Ia_RMS * Va_RMS;
            Qa = sqrt(Sa^2 - Pa^2);
        
            Pb = sum(Vb_signal_window .* Ib_signal_window, 'all') / length(Vb_signal_window);
            Sb = Ib_RMS * Vb_RMS;
            Qb = sqrt(Sb^2 - Pb^2);
        
            Pc = sum(Vc_signal_window .* Ic_signal_window, 'all') / length(Vc_signal_window);
            Sc = Ic_RMS * Vc_RMS;
            Qc = sqrt(Sc^2 - Pc^2);

            P = Pa + Pb + Pc;

            table_values(period+1,:) = [Pa, Sa, Qa, Pb, Sb, Qb, Pc, Sc, Qc];
        end

        % После завершения расчетов, вызовите функцию для отображения таблицы
        showTable(table_values);
    end

    % Функция для обработки данных
    function processData
        % Объявляем данные как глобальные, чтобы они были доступны в колбэк-функции
        %global Ia_signal Va_signal Ib_signal Vb_signal Ic_signal Vc_signal Fs Fmain Nperiod Tperiod Nperiods table_values;
        
        % Предполагается, что функция ReadComtrade загружает данные и присваивает их структуре ans
        ReadComtrade();
        signals = struct();

        checks = getappdata(hFig, 'AssemblyChecks');
        numAssemblies = 0; % Количество сборок по каждому типу
        includeAssembly1 = get(checks(1), 'Value');
        includeAssembly2 = get(checks(2), 'Value');
        includeAssembly3 = get(checks(3), 'Value');
        includeAssembly4 = get(checks(4), 'Value');

        Va_signal = ans.Data.Analog.x_VaFC;
        Vb_signal = ans.Data.Analog.x_VbFC;
        Vc_signal = ans.Data.Analog.x_VcFC;

        Ia_signal = (zeros(length(Va_signal),1));
        Ib_signal = (zeros(length(Va_signal),1));
        Ic_signal = (zeros(length(Va_signal),1));

        if includeAssembly1
            signals.IaAss1 = ans.Data.Analog.x_IaAss1;
            signals.IbAss1 = ans.Data.Analog.x_IbAss1;
            signals.IcAss1 = ans.Data.Analog.x_IcAss1;

            Ia_signal = Ia_signal + signals.IaAss1;
            Ib_signal = Ib_signal + signals.IbAss1;
            Ic_signal = Ic_signal + signals.IcAss1;

            numAssemblies = numAssemblies + 1;
        end

        if includeAssembly2
            signals.IaAss2 = ans.Data.Analog.x_IaAss2;
            signals.IbAss2 = ans.Data.Analog.x_IbAss2;
            signals.IcAss2 = ans.Data.Analog.x_IcAss2;

            Ia_signal = Ia_signal + signals.IaAss2;
            Ib_signal = Ib_signal + signals.IbAss2;
            Ic_signal = Ic_signal + signals.IcAss2;

            numAssemblies = numAssemblies + 1;
        end

        if includeAssembly3
            signals.IaAss3 = ans.Data.Analog.x_IaAss3;
            signals.IbAss3 = ans.Data.Analog.x_IbAss3;
            signals.IcAss3 = ans.Data.Analog.x_IcAss3;

            Ia_signal = Ia_signal + signals.IaAss3;
            Ib_signal = Ib_signal + signals.IbAss3;
            Ic_signal = Ic_signal + signals.IcAss3;

            numAssemblies = numAssemblies + 1;
        end

        if includeAssembly4
            signals.IaAss4 = ans.Data.Analog.x_IaAss4;
            signals.IbAss4 = ans.Data.Analog.x_IbAss4;
            signals.IcAss4 = ans.Data.Analog.x_IcAss4;

            Ia_signal = Ia_signal + signals.IaAss4;
            Ib_signal = Ib_signal + signals.IbAss4;
            Ic_signal = Ic_signal + signals.IcAss4;

            numAssemblies = numAssemblies + 1;
        end

        Fs = ans.Config.SampleRate; % Sample rate [Hz]
        Fmain = ans.Config.Frequency; % Main frequency: 50 or 60 [Hz]

        % После загрузки и инициализации данных, выполнить анализ и отобразить графики
        analyzeAndPlot();

        % Обновление GUI текста
        set(hResultsText, 'String', 'Data loaded and graphs are updated.');
    end

    

        % Функция для отображения таблицы результатов
    function showTable(data)
        % Проверяем, существует ли уже окно с таблицей
        hTableFig = findobj('Tag', 'ResultsTableWindow');
        if isempty(hTableFig)
            % Создаем новое окно для таблицы, если оно не существует
            hTableFig = figure('Tag', 'ResultsTableWindow', 'Name', 'Results Table', 'NumberTitle', 'off', ...
                               'Position', [300, 300, 700, 450], 'Resize', 'off');
            movegui(hTableFig, 'center');  % Центрирование окна на экране
            % Создаем таблицу в этом окне
            hTable = uitable(hTableFig, 'Data', data, ...
                             'Position', [20, 20, 660, 410], 'ColumnWidth', {50});
        else
            % Очищаем окно с таблицей, если оно уже существует
            figure(hTableFig); % Сделаем окно активным
            clf(hTableFig); % Очистим фигуру
            % Создаем новую таблицу с обновленными данными
            hTable = uitable(hTableFig, 'Data', data, ...
                             'Position', [20, 20, 660, 410], 'ColumnWidth', {50});
        end
        
        % Задаем имена столбцов для таблицы
        columnNames = {'Pa', 'Sa', 'Qa', 'Pb', 'Sb', 'Qb', 'Pc', 'Sc', 'Qc'};
        set(hTable, 'ColumnName', columnNames);
    end


end
