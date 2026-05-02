import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

import "../../../../exts.dart";
import "../../../cubits/send_cubit.dart";
import "send/send_connecting_state.dart";
import "send/send_importing_state.dart";
import "send/send_initial_state.dart";
import "send/send_ready_state.dart";

class SendView extends StatelessWidget {
  static const double maxWidth = 500;

  const SendView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SendCubit(context.read()),
      child: BlocConsumer<SendCubit, SendState>(
        listener: (BuildContext context, SendState state) {
          if (state is SendInitial && state.isError) {
            context.showErrorSnackBar(
              "Error occurred while preparing to send.",
            );
            context.read<SendCubit>().clearError();
          }
        },
        builder: (context, state) {
          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(24),
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: SendView.maxWidth,
                    ),
                    child: switch (state) {
                      SendInitial() => const SendInitialStateWidget(),
                      SendImporting(:final progresses) =>
                        SendImportingStateWidget(progresses: progresses),
                      SendConnecting() => const SendConnectingStateWidget(),
                      SendReady(
                        :final ticket,
                        :final size,
                        :final addrs,
                        :final progresses,
                      ) =>
                        SendReadyStateWidget(
                          ticket: ticket,
                          size: size,
                          progresses: progresses.toList(),
                          addrs: addrs,
                        ),
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
