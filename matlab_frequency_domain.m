function three_phase_power_gui
% Графический интерфейс пользователя для анализа трехфазной сети

    % Создание главного окна интерфейса
    hFig = figure('Name', 'Power Meter in Freq domain', 'NumberTitle', 'off', ...
                  'MenuBar', 'none', 'Toolbar', 'none', 'Position', [100, 100, 1000, 600], ...
                  'CloseRequestFcn', @closeAllWindows);
    % Сохраните хендлы других окон в глобальной переменной или в свойстве hMainFig для доступа
    setappdata(hFig, 'ChildWindows', []); % Инициализируем пустым массивом
    
    %% Изменение: Добавление элементов управления для Harmonics
    hHarmonicsText = uicontrol('Style', 'text', 'String', 'Number of Harmonics:', ...
                               'Position', [50, 550, 150, 20]);
    hHarmonicsEdit = uicontrol('Style', 'edit', 'String', '7', ...
                               'Position', [210, 550, 50, 20]);

    %% Изменение: Добавление элементов управления для L
    hLText = uicontrol('Style', 'text', 'String', 'Number of Points L:', ...
                       'Position', [50, 470, 150, 20]);
    hLEdit = uicontrol('Style', 'edit', 'String', '1024', ...
                       'Position', [210, 470, 50, 20]);

    % Создание кнопок для управления процессом
    hLoadButton = uicontrol('Style', 'pushbutton', 'String', 'Load Data', ...
                            'Position', [50, 500, 100, 30], 'Callback', @loadDataCallback);

    %% Изменение: Кнопка для перестроения графиков
    hUpdateButton = uicontrol('Style', 'pushbutton', 'String', 'Update Graphs', ...
                              'Position', [160, 500, 100, 30], 'Callback', @updateGraphs);

    % Место для отображения результатов
    hResultsText = uicontrol('Style', 'text', 'String', 'Results will be shown here', ...
                             'HorizontalAlignment', 'left', 'Position', [50, 50, 700, 400]);

    % Create the checkbox
    hCheckboxAsqrt2 = uicontrol('Style', 'checkbox', ...
                            'String', 'A/sqrt(2)', ...
                            'Position', [50, 250, 120, 20], ...
                            'Value', 1);
    
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
    global Ia_signal Va_signal Ib_signal Vb_signal Ic_signal Vc_signal Fs Fmain Nperiod Tperiod Nperiods table_values Harmonics IaAss1;

    % Инициализация Harmonics
    Harmonics = str2double(get(hHarmonicsEdit, 'String'));

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
        Harmonics = str2double(get(hHarmonicsEdit, 'String'));

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
        Harmonics = str2double(get(hHarmonicsEdit, 'String'));
        L = str2double(get(hLEdit, 'String'))
        applyWindow = get(hWindowFunctionCheck, 'Value'); % Состояние чекбокса оконной функции

        % Проверка на корректность введенных значений
        if isnan(Harmonics) || isnan(L) || L <= 0 || mod(L, 1) ~= 0
            set(hResultsText, 'String', 'Please enter valid Harmonics and L values.');
            return;
        end

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
            % Сохранение хендла дочернего окна
            childWindows = getappdata(hFig, 'ChildWindows');
            setappdata(hFig, 'ChildWindows', [childWindows, hGraphsFig]);
        else
            % Очищаем окно с графиками, если оно уже существует
            figure(hGraphsFig);
            clf(hGraphsFig);
        end
        % Здесь ваш код для создания графиков...
        Nperiod = Fs / Fmain; % Length of one period [counts]
        Tperiod = 1 / Fmain; % Time of one period [s]
        Nperiods = floor(length(Va_signal) / Fs / Tperiod); % Quantity of completed periods

        table_values = zeros(Nperiods, 18);
        
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
            
            t = (0:L-1)*Tperiod;
            
            %'a' phase
            Ia_fft = fft(Ia_signal_window,L);
            Ia_P2 = abs(Ia_fft/L);
            Ia_P1 = Ia_P2(1:L/2+1);
            Ia_P1(2:end-1) = 2*Ia_P1(2:end-1);
            
            Ia_phases = unwrap(angle(Ia_fft));
            Ia_phases = Ia_phases(1:L/2+1);
            
            Va_fft = fft(Va_signal_window,L);
            Va_P2 = abs(Va_fft/L);
            Va_P1 = Va_P2(1:L/2+1);
            Va_P1(2:end-1) = 2*Va_P1(2:end-1);
            
            Va_phases = unwrap(angle(Va_fft));
            Va_phases = Va_phases(1:L/2+1);
        
            %'b' phase
            Ib_fft = fft(Ib_signal_window,L);
            Ib_P2 = abs(Ib_fft/L);
            Ib_P1 = Ib_P2(1:L/2+1);
            Ib_P1(2:end-1) = 2*Ib_P1(2:end-1);
            
            Ib_phases = unwrap(angle(Ib_fft));
            Ib_phases = Ib_phases(1:L/2+1);
            
            Vb_fft = fft(Vb_signal_window,L);
            Vb_P2 = abs(Vb_fft/L);
            Vb_P1 = Vb_P2(1:L/2+1);
            Vb_P1(2:end-1) = 2*Vb_P1(2:end-1);
            
            Vb_phases = unwrap(angle(Vb_fft));
            Vb_phases = Vb_phases(1:L/2+1);
        
            %'c' phase
            Ic_fft = fft(Ic_signal_window,L);
            Ic_P2 = abs(Ic_fft/L);
            Ic_P1 = Ic_P2(1:L/2+1);
            Ic_P1(2:end-1) = 2*Ic_P1(2:end-1);
            
            Ic_phases = unwrap(angle(Ic_fft));
            Ic_phases = Ic_phases(1:L/2+1);
            
            Vc_fft = fft(Vc_signal_window,L);
            Vc_P2 = abs(Vc_fft/L);
            Vc_P1 = Vc_P2(1:L/2+1);
            Vc_P1(2:end-1) = 2*Vc_P1(2:end-1);
            
            Vc_phases = unwrap(angle(Vc_fft));
            Vc_phases = Vc_phases(1:L/2+1);
            
            f = Fs/L*(0:(L/2));
            
            subplot(3,4,1)
            bar(f(1:Harmonics), Va_P1(1:Harmonics));
            grid on;
            title('fft(Va)'); % Заголовок графика
            subplot(3,4,2)
            bar(f(1:Harmonics), Ia_P1(1:Harmonics));
            grid on;
            title('fft(Ia)'); % Заголовок графика
            
            subplot(3,4,5)
            bar(f(1:Harmonics), Vb_P1(1:Harmonics));
            grid on;
            title('fft(Vb)'); % Заголовок графика
            subplot(3,4,6)
            bar(f(1:Harmonics), Ib_P1(1:Harmonics));
            grid on;
            title('fft(Ib)'); % Заголовок графика
        
            subplot(3,4,9)
            bar(f(1:Harmonics), Vc_P1(1:Harmonics));
            grid on;
            title('fft(Vc)'); % Заголовок графика
            subplot(3,4,10)
            bar(f(1:Harmonics), Ic_P1(1:Harmonics));
            grid on;
            title('fft(Ic)'); % Заголовок графика
        
            Fi_a = Va_phases - Ia_phases;
            Fi_b = Vb_phases - Ib_phases;
            Fi_c = Vc_phases - Ic_phases;

            subplot(3,4,3)
            plot(f(1:Harmonics), cos(Fi_a(1:Harmonics)));
            grid on;
            title('cos(fi_a)'); % Заголовок графика
            subplot(3,4,7)
            plot(f(1:Harmonics), cos(Fi_b(1:Harmonics)));
            grid on;
            title('cos(fi_b)'); % Заголовок графика
            subplot(3,4,11)
            plot(f(1:Harmonics), cos(Fi_c(1:Harmonics)));
            grid on;
            title('cos(fi_c)'); % Заголовок графика
            
            Sa = Va_P1(1:Harmonics) .* Ia_P1(1:Harmonics);
            Sb = Vb_P1(1:Harmonics) .* Ib_P1(1:Harmonics);
            Sc = Vc_P1(1:Harmonics) .* Ic_P1(1:Harmonics);

            Pa = Va_P1(1:Harmonics) .* Ia_P1(1:Harmonics) .* cos(Fi_a(1:Harmonics));
            Pb = Vb_P1(1:Harmonics) .* Ib_P1(1:Harmonics) .* cos(Fi_b(1:Harmonics));
            Pc = Vc_P1(1:Harmonics) .* Ic_P1(1:Harmonics) .* cos(Fi_c(1:Harmonics));

            Qa = Va_P1(1:Harmonics) .* Ia_P1(1:Harmonics) .* sin(Fi_a(1:Harmonics));
            Qb = Vb_P1(1:Harmonics) .* Ib_P1(1:Harmonics) .* sin(Fi_b(1:Harmonics));
            Qc = Vc_P1(1:Harmonics) .* Ic_P1(1:Harmonics) .* sin(Fi_c(1:Harmonics));
            
            subplot(3,4,4)
            bar(f(1:Harmonics), Sa)
            grid on;
            set(gca, 'YScale', 'log');  % Установка логарифмической шкалы для оси Y
            xlims = get(gca, 'XLim'); % Get the current x-axis limits
            ylims = get(gca, 'YLim'); % Get the current y-axis limits
            text(xlims(2)*1.1, ylims(2)/2, sprintf('Sa = %.0f VA', sum(Sa)), 'HorizontalAlignment', 'center');
            text(xlims(2)*1.1, ylims(2)/2 - (ylims(2)/3), sprintf('Pa = %.0f W', sum(Pa)), 'HorizontalAlignment', 'center');
            text(xlims(2)*1.1, ylims(2)/2 - (ylims(2)/2.25), sprintf('Qa = %.0f var', sum(Qa)), 'HorizontalAlignment', 'center');
            subplot(3,4,8)
            bar(f(1:Harmonics), Sb)
            grid on;
            set(gca, 'YScale', 'log');  % Установка логарифмической шкалы для оси Y
            xlims = get(gca, 'XLim'); % Get the current x-axis limits
            ylims = get(gca, 'YLim'); % Get the current y-axis limits
            text(xlims(2)*1.1, ylims(2)/2, sprintf('Sb = %.0f VA', sum(Sb)), 'HorizontalAlignment', 'center');
            text(xlims(2)*1.1, ylims(2)/2 - (ylims(2)/3), sprintf('Pb = %.0f W', sum(Pb)), 'HorizontalAlignment', 'center');
            text(xlims(2)*1.1, ylims(2)/2 - (ylims(2)/2.25), sprintf('Qb = %.0f var', sum(Qb)), 'HorizontalAlignment', 'center');
            subplot(3,4,12)
            bar(f(1:Harmonics), Sc)
            grid on;
            set(gca, 'YScale', 'log');  % Установка логарифмической шкалы для оси Y
            xlims = get(gca, 'XLim'); % Get the current x-axis limits
            ylims = get(gca, 'YLim'); % Get the current y-axis limits
            text(xlims(2)*1.1, ylims(2)/2, sprintf('Sc = %.0f VA', sum(Sc)), 'HorizontalAlignment', 'center');
            text(xlims(2)*1.1, ylims(2)/2 - (ylims(2)/3), sprintf('Pc = %.0f W', sum(Pc)), 'HorizontalAlignment', 'center');
            text(xlims(2)*1.1, ylims(2)/2 - (ylims(2)/2.25), sprintf('Qc = %.0f var', sum(Qc)), 'HorizontalAlignment', 'center');

            % S = sqrt(Sa_1plus^2 + Sb_1plus^2 + Sc_1plus^2);
            P = sum(Pa + Pb + Pc)
            Q = sum(Qa + Qb + Qc)
            S = sum(Sa + Sb + Sc)

            Va_RMS = sqrt(sum(Va_P1(1:Harmonics).^2))
            Vb_RMS = sqrt(sum(Vb_P1(1:Harmonics).^2))
            Vc_RMS = sqrt(sum(Vc_P1(1:Harmonics).^2))
            
            Ia_RMS = sqrt(sum(Ia_P1(1:Harmonics).^2))
            Ib_RMS = sqrt(sum(Ib_P1(1:Harmonics).^2))
            Ic_RMS = sqrt(sum(Ic_P1(1:Harmonics).^2))

            V_RMS = mean([Va_RMS, Vb_RMS, Vc_RMS]) * sqrt(3)
            I_RMS = mean([Ia_RMS, Ib_RMS, Ic_RMS])

            % table_values(period+1,:) = [Sa_Michail, Ssum1_Michail, S, Pa_1plus, Pa_H,   Pa(1),   Sa_1plus,   Sa_e1,   Sa_u1,   Da_eI,   Da_eV,   Sa_eH,   Sa_eN,   Na,   Sa_e,   Qa_1plus,   PFa_1plus,   PFa];
        end

        % После завершения расчетов, вызовите функцию для отображения таблицы
        %showTable(table_values);
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

        isAdivSqrt2 = get(hCheckboxAsqrt2, 'Value') % Get the value of the checkbox (1 for checked, 0 for unchecked)
        if isAdivSqrt2
            Ia_signal = Ia_signal ./ sqrt(2);
            Ib_signal = Ib_signal ./ sqrt(2);
            Ic_signal = Ic_signal ./ sqrt(2);

            Va_signal = ans.Data.Analog.x_VaFC ./ sqrt(2);
            Vb_signal = ans.Data.Analog.x_VbFC ./ sqrt(2);
            Vc_signal = ans.Data.Analog.x_VcFC ./ sqrt(2);
        end

        Fs = ans.Config.SampleRate; % Sample rate [Hz]
        Fmain = ans.Config.Frequency; % Main frequency: 50 or 60 [Hz]

        % Инициализация фигуры
        hFigFFT = figure('Name', 'FFT Analysis', 'NumberTitle', 'off', ...
                      'Position', [100, 100, 1200, 800]);
    
        % Массивы с названиями сборок
        assemblies = {'Ia', 'Ib', 'Ic'};
    
        % Обход всех сборок и подсборок
        for i = 1:length(assemblies)
            for j = 1:numAssemblies
                % Индекс для субплота
                subplotIndex = (i-1) * numAssemblies + j;
                subplot(length(assemblies), numAssemblies, subplotIndex);
    
                % Генерация имени переменной (пример: IaAss1)
                signalName = sprintf('%sAss%d', assemblies{i}, j);
    
                % Выполнение FFT
                L = 1024;
                Y = fft(signals.(signalName)(1:1024+1),L);
                P2 = abs(Y/L);
                P1 = P2(1:L/2+1);
                P1(2:end-1) = 2*P1(2:end-1);
                f = Fs/L*(0:(L/2));
    
                % Построение графика
                bar(f(1:Harmonics), P1(1:Harmonics));
                title(['FFT of ', signalName]);
                xlabel('Frequency (Hz)');
                ylabel('|P1(f)|');
            end
        end

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
            % Сохранение хендла дочернего окна
            childWindows = getappdata(hFig, 'ChildWindows');
            setappdata(hFig, 'ChildWindows', [childWindows, hTableFig]);
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
        columnNames = {'Sa_Michail', 'Ssum1_Michail', 'S', 'Pa_1plus', 'Pa_H',   'Pa',   'Sa_1plus',   'Sa_e1',   'Sa_u1',   'Da_eI',   'Da_eV',   'Sa_eH',   'Sa_eN',   'Na',   'Sa_e',   'Qa_1plus',   'PFa_1plus',   'PFa'};
        set(hTable, 'ColumnName', columnNames);
    end
    
    
    function closeAllWindows(src, event)
        % Получение списка дочерних окон
        childWindows = getappdata(src, 'ChildWindows');
        
        % Закрытие всех дочерних окон
        for i = 1:length(childWindows)
            if ishandle(childWindows(i))
                close(childWindows(i));
            end
        end
        
        % Закрытие главного окна
        delete(src);
    end


end
