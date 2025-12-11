package dev.panimal.shadermaxxing.registry;

import com.mojang.brigadier.CommandDispatcher;
import com.mojang.brigadier.exceptions.SimpleCommandExceptionType;
import dev.panimal.shadermaxxing.commands.GurtCommand;
import dev.panimal.shadermaxxing.commands.ShaderEventCommand;
import net.minecraft.command.CommandRegistryAccess;
import net.minecraft.server.command.CommandManager;
import net.minecraft.server.command.ServerCommandSource;
import net.minecraft.text.Text;
import org.jetbrains.annotations.Nullable;

public class ShaderCommands {

    public static void register(CommandDispatcher<ServerCommandSource>dispatcher, CommandRegistryAccess registryAccess, CommandManager.RegistrationEnvironment environment)
    {
        GurtCommand.register(dispatcher);
        ShaderEventCommand.register(dispatcher);
    }

    @Deprecated
    @SuppressWarnings("DeprecatedIsStillUsed")
    @Nullable
    public static CommandRegistryAccess commandRegistryAccess = null;
    public static final SimpleCommandExceptionType REGISTRY_NULL_EXCEPTION = new SimpleCommandExceptionType(Text.translatable("shadermaxxing.command.registry_null"));
}
