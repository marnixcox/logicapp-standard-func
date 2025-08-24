namespace functions.Interface
{
    public interface IMapper<in TInput, TOutput>
    {
        public Task<TOutput> Map(TInput input);
    }
}
