import dlangui;
import plot2d;

mixin APP_ENTRY_POINT;


extern(C) int UIAppMain(string[] args) {
    auto window = prepareWindow();
    auto plot = window.mainWidget.childById!PlotWidget("plot");
    auto table = window.mainWidget.childById!TableWidget("table");

    return Platform.instance.enterMessageLoop();
}

auto mainLayout() {
    return parseML(q{
        HorizontalLayout {
            layoutWidth: fill
            VerticalLayout {
                layoutHeight: fill
                PlotWidget {
                    id: "plot"
                    minHeight: 800
                    minWidth: 1000
                }
                ResizerWidget {}
                EditBox {
                    id: "formulas"
                    text: "@A1\n@A2\ny{green} = x^1.3"
                }
            }
            ResizerWidget {}
            VerticalLayout {
                layoutHeight: fill
                layoutWidth: fill
                TextWidget {
                    text: "Options and stuff on this side."
                }
                TableWidget {
                    id: "table"
                    rows: 100
                    cols: 6
                }
            }
        }
    });
}

auto prepareWindow() {
    import dlangui.widgets.metadata;
    // TODO: PR on DlangUI for ResizerWidget registration?
    mixin(registerWidgets!("void registerCustomWidgets",
                PlotWidget, TableWidget, ResizerWidget));
    registerCustomWidgets();

    auto window = Platform.instance.createWindow(
            "Interactive Visualizer", null, 1u, 800, 600);

    window.mainWidget = mainLayout();

    auto table = window.mainWidget.childById!TableWidget("table");
    with (table) {
        vscrollbarMode = ScrollBarMode.Invisible;
        minHeight = table.defRowHeight * 6;
        layoutWidth = FILL_PARENT;
        setCellText(0, 0, "y{blue} = x^2 + 1");
        setCellText(0, 1, "y{red} = x^0.5");
        setColumnHeaders();
        setRowHeaders();
        autoFit();
    }

    window.show();
    return window;
}

class PlotWidget : CanvasWidget {
    Plot plot;
    DlangUICtx ctx;

    this(string id = null) {
        import plot2d.types : PlotPoint = Point;
        super(id);

        plot = new Plot();
        plot.settings.minGridStep.x = 80;
        plot.settings.minGridStep.y = 80;
        ctx = new DlangUICtx();

        plot.settings.viewport = Viewport(DimSeg(-50,50), DimSeg(-40, 80));
        plot.settings.autoFit = false;
        plot.settings.padding = Border(0);


        PlotPoint[] points;
        PlotPoint[] points2;
        PlotPoint[] points3;
        for (auto x = plot.settings.viewport.w.min; x < plot.settings.viewport.w.max; ++x) {
            points ~= PlotPoint(cast(int)x, cast(int)x^^2 + 1);
            if (x > 0.0) {
                points2 ~= PlotPoint(cast(int)x, cast(int)(x^^(0.5)));
                points3 ~= PlotPoint(cast(int)x, cast(int)(x^^(1.3)));
            }
        }

        plot.add(
            new LineChart(
                PColor.blue,
                (ref Appender!(PlotPoint[]) buf) { buf.put(points); }
        ));
        plot.add(
            new LineChart(
                PColor.red,
                (ref Appender!(PlotPoint[]) buf) { buf.put(points2); }
        ));
        plot.add(
            new LineChart(
                PColor.green,
                (ref Appender!(PlotPoint[]) buf) { buf.put(points3); }
        ));
    }


    override void doDraw(DrawBuf buf, Rect rc) {
        buf.fillRect(rc, 0xaaaaaa);
        auto _ = ctx.set(buf);
        plot.updateCharts();
        plot.draw(ctx, PPoint(this.width, this.height));
    }
}

class TableWidget : StringGridWidget {
    this(string id = null) {
        super(id);

        this.cellSelected = new TableWidgetEventHandler();
    }

    void setColumnHeaders() {
        import intervis.bijectiveb26;
        auto columnHeader = BijectiveB26("A");

        for (int i = 0; i < this.cols(); ++i) {
            if (this.colTitle(i) is null) {
                this.setColTitle(i, columnHeader.value);
                ++columnHeader;
            }
        }
    }

    void setRowHeaders() {
        import std.conv : to;
        for (int i = 0; i < this.rows(); ++i) {
            if (this.rowTitle(i) is null) {
                this.setRowTitle(i, (i+1).to!dstring);
            }
        }
    }

    override bool onKeyEvent(KeyEvent event) {
        if (event.action == KeyAction.Text) {
            setCellText(
                    selectedCol, selectedRow,
                    cellText(selectedCol, selectedRow) ~ event.text);

            /+ TODO: Why won't this work?
                It will only expand a column if the next column is edited.
            this.autoFitColumnWidth(selectedCol);
            if (this.width < this.defColumnWidth)
                this.setColWidth(selectedCol, defColumnWidth);
            this.invalidate();
            +/

            this.autoFitColumnWidths();
        }
        return true;
    }

    private:

    int selectedCol;
    int selectedRow;

    class TableWidgetEventHandler : CellSelectedHandler {
        void onCellSelected(GridWidgetBase source, int col, int row) {
            selectedCol = col;
            selectedRow = row;
        }
    }
}

