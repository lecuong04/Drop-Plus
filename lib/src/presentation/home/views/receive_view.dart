import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

import "../../../../exts.dart";
import "../../../cubits/receive_cubit.dart";
import "receive/receive_connecting_state.dart";
import "receive/receive_exporting_state.dart";
import "receive/receive_initial_state.dart";
import "receive/receive_pending_state.dart";
import "receive/receive_success_state.dart";
import "receive/receive_transferring_state.dart";
import "receive/receive_validating_state.dart";

class ReceiveView extends StatefulWidget {
  static const double maxWidth = 500;

  const ReceiveView({super.key});

  @override
  State<ReceiveView> createState() => _ReceiveViewState();
}

class _ReceiveViewState extends State<ReceiveView> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReceiveCubit(context.read()),
      child: BlocConsumer<ReceiveCubit, ReceiveState>(
        listener: (context, state) {
          if (state is ReceiveInitial && state.isError) {
            context.showErrorSnackBar("Error occurred while receiving files.");
            context.read<ReceiveCubit>().clearError();
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(24),
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: ReceiveView.maxWidth,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.05),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: switch (state) {
                          ReceiveInitial() => const ReceiveInitialStateWidget(),
                          ReceivePending(:final isWaiting, :final files) =>
                            ReceivePendingStateWidget(
                              files: files,
                              isWaiting: isWaiting,
                            ),
                          ReceiveConnecting() =>
                            const ReceiveConnectingStateWidget(),
                          ReceiveValidating() =>
                            const ReceiveValidatingStateWidget(),
                          ReceiveTransferring(:final progresses) =>
                            ReceiveTransferringStateWidget(
                              progresses: progresses,
                            ),
                          ReceiveExporting(:final progresses) =>
                            ReceiveExportingStateWidget(progresses: progresses),
                          ReceiveSuccess(:final result) =>
                            ReceiveSuccessStateWidget(result: result),
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
