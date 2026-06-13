import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:storypilot/ui/auth/bloc/auth_bloc.dart';
import 'package:storypilot/ui/auth/bloc/auth_event.dart';
import 'package:storypilot/ui/auth/bloc/auth_state.dart';

class AuthAppBarActions extends StatelessWidget {
  const AuthAppBarActions({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) => switch (state) {
        AuthAuthenticated(:final email) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: email,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    email,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.read<AuthBloc>().add(
                      const AuthSignOutRequested(),
                    ),
                child: const Text('Salir'),
              ),
            ],
          ),
        _ => TextButton(
            onPressed: () => context.push('/login'),
            child: const Text('Iniciar sesión'),
          ),
      },
    );
  }
}
