using functions.Interface;

namespace Microsoft.Extensions.DependencyInjection
{
    public static class FunctionsStartupExtensions
    {
        /// <summary>
        /// Registers all classes implementing IMapper&lt;TInput, TOutput&gt; in assembly of type T
        /// </summary>
        /// <param name="services">IServiceCollection</param>
        /// <typeparam name="T">Type of class whose assembly to scan (Startup class)</typeparam>
        /// <returns>The IServiceCollection</returns>
        public static IServiceCollection AddMappers<T>(this IServiceCollection services)
        {
            services.Scan(scan => scan
                .FromAssemblyOf<T>()
                .AddClasses(classes => classes.AssignableTo(typeof(IMapper<,>)))
                .AsImplementedInterfaces()
                .WithSingletonLifetime());

            return services;
        }

    }
}