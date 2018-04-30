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
    table.vscrollbarMode = ScrollBarMode.Invisible;
    table.minHeight = table.defRowHeight * 6;
    table.layoutWidth = FILL_PARENT;
    table.setCellText(0, 0, "y = x^2 + 1");
    table.autoFit();

    window.show();
    return window;
}

/++ Pulled this from plot2d example to use until I'm ready to work on the graph. +/

class PlotWidget : CanvasWidget {
    Plot plot;
    DlangUICtx ctx;

    this(string id = null) {
        super(id);

        plot = new Plot;
        plot.settings.minGridStep.x = 80;
        plot.settings.minGridStep.y = 80;
        ctx = new DlangUICtx;

        auto mf(float i) { return sin(i*sin(i+ct()*0.5)*PI*2); }
        auto tre = iota(-2, 2.02, 0.02)
            .map!(i=>TreStat(i, mf(i) + 0.4 + sin(i*PI*2+ct*3) * 0.3,
                            mf(i), mf(i) - 0.4 - sin(i*PI*2+ct*5) * 0.3));

        plot.add(new TreChart(
            PColor(0,0.5,0,0.8),

            PColor(1,1,0,.3),
            PColor(1,1,0,.2),

            PColor(0,1,1,.3),
            PColor(0,1,1,.2),
            (ref Appender!(TreStat[]) buf) { buf.put(tre.save); }
        ));

        plot.settings.viewport = Viewport(DimSeg(-2,2), DimSeg(-1, 2));
        plot.settings.autoFit = false;
        plot.settings.padding = Border(0);
    }

    auto ct() {
        import std.datetime : Clock;
        return Clock.currStdTime / 1e7;
    }

    override void doDraw(DrawBuf buf, Rect rc) {
        buf.fillRect(rc, 0xaaaaaa);
        auto _ = ctx.set(buf);
        plot.updateCharts();
        plot.draw(ctx, PPoint(this.width, this.height));
    }
}

/++ END plot2d example. +/

class TableWidget : StringGridWidget {
    this(string id = null) {
        super(id);

        this.cellSelected = new TableWidgetEventHandler();
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

